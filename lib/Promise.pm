package Promise;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
our $VERSION = '5.0';
use Carp;
push our @CARP_NOT, qw(Promise::TypeError);

## Not public; using |our| such that |local| can be used.
our $CallerLevel = 0;

$Promise::CreateTypeError ||= sub ($$) {
  require Promise::TypeError;
  $Promise::CreateTypeError = sub ($$) {
    return Promise::TypeError->new ($_[1]);
  };
  return $Promise::CreateTypeError->(@_);
};
sub _type_error ($) { $Promise::CreateTypeError->(undef, $_[0]) }

$Promise::Enqueue = sub ($$) {
  require AnyEvent;
  &AE::postpone ($_[1]);
  $Promise::Enqueue = sub { &AE::postpone ($_[1]) };
};
sub _enqueue (&) { $Promise::Enqueue->(undef, $_[0]) }

$Promise::RejectionTrackerReject = sub ($) { };
$Promise::RejectionTrackerHandle = sub ($) { };
sub _rejection_tracker_reject ($) { $Promise::RejectionTrackerReject->(@_) }
sub _rejection_tracker_handle ($) { $Promise::RejectionTrackerHandle->(@_) }

sub _enqueue_promise_reaction_job ($$) {
  my ($reaction, $argument) = @_;
  _enqueue {
    ## PromiseReactionJob
    my $promise_capability = $reaction->{capability};
    if (defined $reaction->{handler}) {
      my $file = $reaction->{caller}->[1];
      $file =~ s/[\x0D\x0A\x22]/_/g;
      my $handler_result;
      my $eval_result = eval sprintf q{
package Promise::_Dummy;
#line %d "%s"
$handler_result = $reaction->{handler}->($argument);
1;
}, $reaction->{caller}->[2], $file;
      return $promise_capability->{reject}->($@) unless $eval_result;
      return $promise_capability->{resolve}->($handler_result);
    } else {
      if ($reaction->{type} eq 'fulfill') {
        return $promise_capability->{resolve}->($argument);
      } else { # reject
        return $promise_capability->{reject}->($argument);
      }
    }
  };
} # _enqueue_promise_reaction_job

sub _create_resolving_functions ($);

sub _enqueue_promise_resolve_thenable_job ($$$) {
  my ($promise_to_resolve, $thenable, $then) = @_;
  _enqueue {
    ## PromiseResolveThenableJob
    my $resolving_functions = _create_resolving_functions $promise_to_resolve;
    my $eval_result = eval {
      # gives scalar context
      my $then_call_result = $then->($thenable, $resolving_functions->{resolve}, $resolving_functions->{reject});
      1;
    };
    return $resolving_functions->{reject}->($@) unless $eval_result;
    #return $then_call_result; # unused
  };
} # _enqueue_promise_resolve_thenable_job

sub _fulfill_promise ($$) {
  my $promise = $_[0];
  my $reactions = delete $promise->{promise_fulfill_reactions};
  $promise->{promise_result} = $_[1];
  delete $promise->{promise_reject_reactions};
  $promise->{promise_state} = 'fulfilled';

  ## TriggerPromiseReactions
  _enqueue_promise_reaction_job $_, $_[1] for @$reactions;

  return undef;
} # _fulfill_promise

sub _reject_promise ($$) {
  my $promise = $_[0];
  my $reactions = delete $promise->{promise_reject_reactions};
  $promise->{promise_result} = $_[1];
  delete $promise->{promise_fulfill_reactions};
  $promise->{promise_state} = 'rejected';
  _rejection_tracker_reject $promise unless $promise->{promise_is_handled};

  ## TriggerPromiseReactions
  _enqueue_promise_reaction_job $_, $_[1] for @$reactions;

  return undef;
} # _reject_promise

sub _create_resolving_functions ($) {
  my ($promise) = @_;
  my $already_resolved = 0;
  my $resolve = sub ($$) { ## promise resolve function
    return undef if $already_resolved;
    $already_resolved = 1;
    return _reject_promise $promise, _type_error ('SelfResolutionError')
        if defined $_[0] and $_[0] eq $promise; ## SameValue
    return _fulfill_promise $promise, $_[0]
        if not defined $_[0] or not ref $_[0];
    local $@;
    my $then;
    my $eval_result = eval {
      $then = UNIVERSAL::can ($_[0], 'then') && $_[0]->can ('then');
      1;
    };
    return _reject_promise $promise, $@ unless $eval_result;
    return _fulfill_promise $promise, $_[0]
        unless defined $then and ref $then eq 'CODE';
    _enqueue_promise_resolve_thenable_job $promise, $_[0], $then;
    return undef;
  };
  my $reject = sub ($$) { ## promise reject function
    return undef if $already_resolved;
    $already_resolved = 1;
    return _reject_promise $promise, $_[0];
  };
  return {resolve => $resolve, reject => $reject};
} # _create_resolving_functions

sub _new_promise_capability ($) {
  my $class = $_[0];
  my $promise_capability = {}; # promise, resolve, reject

  ## GetCapabilitiesExecutor
  my $executor = sub ($$) {
    die _type_error ('The resolver is already specified')
        if defined $promise_capability->{resolve};
    die _type_error ('The reject handler is already specified')
        if defined $promise_capability->{reject};
    $promise_capability->{resolve} = $_[0];
    $promise_capability->{reject} = $_[1];
    return undef;
  };

  local $CallerLevel = $CallerLevel + 2;
  $promise_capability->{promise} = $class->new ($executor); # or throw
  die _type_error
      ('The executor is not invoked or the resolver is not specified')
      unless defined $promise_capability->{resolve} and
             ref $promise_capability->{resolve} eq 'CODE';
  die _type_error
      ('The executor is not invoked or the reject handler is not specified')
      unless defined $promise_capability->{reject} and
             ref $promise_capability->{reject} eq 'CODE';
  return $promise_capability;
} # _new_promise_capability

sub new ($$) {
  my ($class, $executor) = @_;
  die _type_error ('The executor is not a code reference')
      unless defined $executor and ref $executor eq 'CODE';
  my $promise = bless {caller => [caller $CallerLevel]}, $class;
  $promise->{promise_state} = 'pending';
  $promise->{promise_fulfill_reactions} = [];
  $promise->{promise_reject_reactions} = [];
  #$promise->{promise_is_handled} = 0;
  my $resolving_functions = _create_resolving_functions $promise;
  {
    local $@;
    my $eval_result = eval {
      $executor->($resolving_functions->{resolve}, $resolving_functions->{reject});
      1;
    };
    $resolving_functions->{reject}->($@) unless $eval_result;
  }
  return $promise;
} # new

sub all ($$) {
  my ($class, $iterable) = @_;
  my $promise_capability = _new_promise_capability $class; # or throw
  local $@;
  my $iterator;
  my $eval_result = eval {
    $iterator = [@$iterable];
    1;
  };
  unless ($eval_result) { ## IfAbruptRejectPromise
    $promise_capability->{reject}->($@);
    return $promise_capability->{promise};
  }
  ## PerformPromiseAll
  my $values = [];
  my $remaining_elements_count = 1;
  my $index = 0;
  {
    unless ($index <= $#$iterator) {
      $remaining_elements_count--;
      if ($remaining_elements_count == 0) {
        $promise_capability->{resolve}->($values); # or throw
      }
      return $promise_capability->{promise};
    }
    my $next_promise;
    my $eval_result = eval {
      $next_promise = $class->resolve ($iterator->[$index]);
      1;
    };
    unless ($eval_result) { ## IfAbruptRejectPromise
      $promise_capability->{reject}->($@);
      return $promise_capability->{promise};
    }
    my $already_called = 0;
    my $resolve_element_index = $index;
    my $resolve_element = sub ($) { ## Promise.all resolve element function
      return undef if $already_called;
      $already_called = 1;
      $values->[$resolve_element_index] = $_[0];
      $remaining_elements_count--;
      if ($remaining_elements_count == 0) {
        return $promise_capability->{resolve}->($values);
      }
      return undef;
    };
    $remaining_elements_count++;
    $eval_result = eval {
      $next_promise->then ($resolve_element, $promise_capability->{reject});
      1;
    };
    unless ($eval_result) { ## IfAbruptRejectPromise
      $promise_capability->{reject}->($@);
      return $promise_capability->{promise};
    }
    $index++;
    redo;
  }
} # all

sub race ($$) {
  my ($class, $iterable) = @_;
  my $promise_capability = _new_promise_capability $class; # or throw
  local $@;
  my $iterator;
  my $eval_result = eval {
    $iterator = [@$iterable];
    1;
  };
  unless ($eval_result) { ## IfAbruptRejectPromise
    $promise_capability->{reject}->($@);
    return $promise_capability->{promise};
  }
  ## PerformPromiseRace
  for my $value (@$iterator) {
    my $eval_result = eval {
      my $promise = $class->resolve ($value);
      scalar $promise->then ($promise_capability->{resolve}, $promise_capability->{reject});
      1;
    };
    unless ($eval_result) { ## IfAbruptRejectPromise
      $promise_capability->{reject}->($@);
      return $promise_capability->{promise};
    }
  } # $value
  return $promise_capability->{promise};
} # race

sub reject ($$) {
  my $promise_capability = _new_promise_capability $_[0]; # or throw
  $promise_capability->{reject}->($_[1]);
  return $promise_capability->{promise};
} # reject

sub resolve ($$) {
  return $_[1] if defined $_[1] and ref $_[1] eq $_[0]; ## IsPromise and constructor
  my $promise_capability = _new_promise_capability $_[0]; # or throw
  $promise_capability->{resolve}->($_[1]);
  return $promise_capability->{promise};
} # resolve

sub catch ($$) {
  local $CallerLevel = 1;
  return $_[0]->then (undef, $_[1]); # or throw
} # catch

sub then ($$$) {
  my ($promise, $onfulfilled, $onrejected) = @_;
  my $promise_capability = _new_promise_capability ref $promise; # or throw

  my $caller = [caller ((sub { Carp::short_error_loc })->() - 1)];

  ## PerformPromiseThen
  if (defined $onfulfilled and not ref $onfulfilled eq 'CODE') {
    warn sprintf "Fulfilled callback is not a CODE (%s) at %s line %s\n",
        $onfulfilled,
        $caller->[1],
        $caller->[2];
    $onfulfilled = undef;
  }
  if (defined $onrejected and not ref $onrejected eq 'CODE') {
    warn sprintf "Rejected callback is not a CODE (%s) at %s line %s\n",
        $onrejected,
        $caller->[1],
        $caller->[2];
    $onrejected = undef;
  }
  my $fulfill_reaction = {type => 'fulfill',
                          capability => $promise_capability,
                          handler => $onfulfilled,
                          caller => $caller};
  my $reject_reaction = {type => 'reject',
                         capability => $promise_capability,
                         handler => $onrejected,
                         caller => $caller};
  if ($promise->{promise_state} eq 'pending') {
    push @{$promise->{promise_fulfill_reactions}}, $fulfill_reaction
        if defined $promise->{promise_fulfill_reactions} and
           ref $promise->{promise_fulfill_reactions} eq 'ARRAY';
    push @{$promise->{promise_reject_reactions}}, $reject_reaction
        if defined $promise->{promise_reject_reactions} and
           ref $promise->{promise_reject_reactions} eq 'ARRAY';
  } elsif ($promise->{promise_state} eq 'fulfilled') {
    _enqueue_promise_reaction_job $fulfill_reaction, $promise->{promise_result};
  } elsif ($promise->{promise_state} eq 'rejected') {
    my $result = $promise->{promise_result};
    _rejection_tracker_handle $promise unless $promise->{promise_is_handled};
    _enqueue_promise_reaction_job $reject_reaction, $result;
  }
  $promise->{promise_is_handled} = 1;
  return $promise_capability->{promise};
} # then

sub manakai_set_handled ($) {
  $_[0]->{promise_is_handled} = 1;
} # manakai_set_handled

sub from_cv ($$) {
  my ($class, $cv) = @_;
  local $CallerLevel = 1;
  return $class->new (sub {
    my ($resolve, $reject) = @_;
    $cv->cb (sub {
      my $eval_result = eval {
        $resolve->($_[0]->recv);
        1;
      };
      $reject->($@) unless $eval_result;
    });
  });
} # from_cv

sub to_cv ($) {
  require AnyEvent;
  my $cv = AE::cv ();
  $_[0]->then (sub {
    $cv->send ($_[0]);
  }, sub {
    $cv->croak ($_[0]);
  });
  return $cv;
} # to_cv

sub debug_info ($) {
  my $self = $_[0];
  no warnings 'uninitialized';
  return sprintf '{%s: %s, created at %s line %s}',
      ref $self,
      $self->{promise_state},
      $self->{caller}->[1],
      $self->{caller}->[2];
} # debug_info

sub DESTROY ($) {
  if (not $_[0]->{promise_is_handled} and
      defined $_[0]->{promise_state} and
      $_[0]->{promise_state} eq 'rejected') {
    my $msg = "$$: Uncaught rejection: @{[defined $_[0]->{promise_result} ? $_[0]->{promise_result} : '(undef)']}";
    $msg .= " for " . $_[0]->debug_info . "\n" unless $msg =~ /\n$/;
    warn $msg;
  }
  local $@;
  eval { die };
  if ($@ =~ /during global destruction/) {
    warn "$$: Reference to " . $_[0]->debug_info . " is not discarded before global destruction\n";
  }
} # DESTROY

1;

=head1 LICENSE

Copyright 2014-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
