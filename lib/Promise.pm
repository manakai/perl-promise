package Promise;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
our $VERSION = '1.0';

use Carp; # XXX
sub TypeError ($) { "TypeError: " . $_[0] . Carp::shortmess }

use AnyEvent;# XXX
sub enqueue ($) {
  my $code = $_[0];
  AE::postpone { $code->() };
} # enqueue

sub enqueue_promise_reaction_job ($$) {
  my ($reaction, $argument) = @_;
  enqueue sub {
    my $promise_capability = $reaction->{capabilities};
    if (ref $reaction->{handler} eq 'CODE') {
      my $handler_result = eval { $reaction->{handler}->($argument) };
      return $promise_capability->{reject}->($@) if $@;
      return $promise_capability->{resolve}->($handler_result);
    } elsif ($reaction->{handler} eq 'thrower') {
      return $promise_capability->{reject}->($argument);
    } else { # handler eq identity
      return $promise_capability->{resolve}->($argument);
    }
  };
} # enqueue_promise_reaction_job

sub create_resolving_functions ($);
sub enqueue_promise_resolve_thenable_job ($$$) {
  my ($promise_to_resolve, $thenable, $then) = @_;
  enqueue sub {
    my $resolving_functions = create_resolving_functions $promise_to_resolve;
    my $then_call_result = eval { $then->($thenable, $resolving_functions->{resolve}, $resolving_functions->{reject}) };
    return $resolving_functions->{reject}->($@) if $@;
    return $then_call_result;
  };
} # enqueue_promise_resolve_thenable_job

sub trigger_promise_reactions ($$) {
  enqueue_promise_reaction_job $_, $_[1] for @{$_[0] or []};
  return undef;
} # trigger_promise_reactions

sub fulfill_promise ($$) {
  my $promise = $_[0];
  $promise->{promise_state} = 'fulfilled';
  delete $promise->{promise_reject_reactions};
  return trigger_promise_reactions
      delete $promise->{promise_fulfill_reactions},
      $promise->{promise_result} = $_[1];
} # fulfill_promise

sub reject_promise ($$) {
  my $promise = $_[0];
  $promise->{promise_state} = 'rejected';
  delete $promise->{promise_fulfill_reactions};
  return trigger_promise_reactions
      delete $promise->{promise_reject_reactions},
      $promise->{promise_result} = $_[1];
} # reject_promise

sub create_resolving_functions ($) {
  my $promise = $_[0];
  my $already_resolved = 0;
  my $resolve = sub ($$) { ## promise resolve function
    my ($resolution) = @_;
    return undef if $already_resolved;
    $already_resolved = 1;
    if (defined $resolution and $resolution eq $promise) { # SameValue
      my $self_resolution_error = TypeError 'SelfResolutionError';
      return reject_promise $promise, $self_resolution_error;
    }
    if (not defined $resolution or not ref $resolution) {
      return fulfill_promise $promise, $resolution;
    }
    my $then = eval { UNIVERSAL::can ($resolution, 'then') && $resolution->can ('then') };
    return reject_promise $promise, $@ if $@;
    unless (defined $then and ref $then eq 'CODE') {
      return fulfill_promise $promise, $resolution;
    }
    enqueue_promise_resolve_thenable_job $promise, $resolution, $then;
    return undef;
  };
  my $reject = sub ($$) { ## promise reject function
    my ($reason) = @_;
    return undef if $already_resolved;
    $already_resolved = 1;
    return reject_promise $promise, $reason;
  };
  return {resolve => $resolve, reject => $reject};
} # create_resolving_functions

sub create_promise_capability_record ($$) {
  my ($promise, $class) = @_;
  my $promise_capability = {promise => $promise};
  my $executor = sub ($$$) { # GetCapabilitiesExecutor function
    die TypeError 'The resolver is already specified'
        if defined $promise_capability->{resolve};
    die TypeError 'The reject handler is already specified'
        if defined $promise_capability->{reject};
    $promise_capability->{resolve} = $_[0];
    $promise_capability->{reject} = $_[1];
    return undef;
  };
  $class->can ('_new')->($promise, $executor); # or throw
  die TypeError 'The executor is not invoked or the resolver is not specified'
      unless ref $promise_capability->{resolve} eq 'CODE';
  die TypeError 'The executor is not invoked or the reject handler is not specified'
      unless ref $promise_capability->{reject} eq 'CODE';
  return $promise_capability;
} # create_promise_capability_record

sub new_promise_capability ($) {
  my $class = $_[0];
  my $promise = bless {}, $class; # CreateFromConstructor
  return create_promise_capability_record $promise, $class;
} # new_promise_capability

sub is_promise ($) {
  return 0 unless defined $_[0] and ref $_[0];
  local $@;
  return defined eval { $_[0]->{promise_state} };
} # is_promise

sub initialize_promise ($$) {
  my ($promise, $executor) = @_;
  $promise->{promise_state} = 'pending';
  $promise->{promise_fulfill_reactions} = [];
  $promise->{promise_reject_reactions} = [];
  my $resolving_functions = create_resolving_functions $promise;
  $executor->($resolving_functions->{resolve}, $resolving_functions->{reject});
  $resolving_functions->{reject}->($@) if $@;
  return $promise;
} # initialize_promise

sub new ($$) {
  my ($class, $executor) = @_;
  my $promise = bless {}, $class;
  $promise->_new ($executor);
  return $promise;
} # new

sub _new ($) {
  my ($promise, $executor) = @_;
  die TypeError 'The executor is not a code reference'
      unless ref $executor eq 'CODE';
  return initialize_promise $promise, $executor;
} # _new

sub all ($$) {
  my ($class, $iterable) = @_;
  my $promise_capability = new_promise_capability $class; # or throw
  my $iterator = [eval { @$iterable }];
  if ($@) { # IfAbruptRejectPromise
    $promise_capability->{reject}->($@);
    return $promise_capability->{promise};
  }
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
    my $next_promise = eval { $class->resolve ($iterator->[$index]) };
    if ($@) { # IfAbruptRejectPromise
      $promise_capability->{reject}->($@);
      return $promise_capability->{promise};
    }
    my $already_called = 0;
    my $resolve_element_index = $index;
    my $resolve_element = sub ($) { # Promise.all resolve element function
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
    eval { $next_promise->then ($resolve_element, $promise_capability->{reject}) };
    if ($@) { # IfAbruptRejectPromise
      $promise_capability->{reject}->($@);
      return $promise_capability->{promise};
    }
    $index++;
    redo;
  }
} # all

sub race ($$) {
  my ($class, $iterable) = @_;
  my $promise_capability = new_promise_capability $class; # or throw
  my $iterator = [eval { @$iterable }];
  if ($@) { # IfAbruptRejectPromise
    $promise_capability->{reject}->($@);
    return $promise_capability->{promise};
  }
  my $index = 0;
  {
    unless ($index <= $#$iterator) {
      return $promise_capability->{promise};
    }
    my $next_promise = eval { $class->resolve ($iterator->[$index]) };
    if ($@) { # IfAbruptRejectPromise
      $promise_capability->{reject}->($@);
      return $promise_capability->{promise};
    }
    eval { $next_promise->then ($promise_capability->{resolve}, $promise_capability->{reject}) };
    if ($@) { # IfAbruptRejectPromise
      $promise_capability->{reject}->($@);
      return $promise_capability->{promise};
    }
    $index++;
    redo;
  }
} # race

sub reject ($$) {
  my ($class, $r) = @_;
  my $promise_capability = new_promise_capability $class; # or throw
  $promise_capability->{reject}->($r);
  return $promise_capability->{promise};
} # reject

sub resolve ($$) {
  my ($class, $x) = @_;
  if (is_promise $x) {
    return $x if ref $x eq $class;
  }
  my $promise_capability = new_promise_capability $class; # or throw
  $promise_capability->{resolve}->($x);
  return $promise_capability->{promise};
} # resolve

sub catch ($$) {
  return $_[0]->then (undef, $_[1]); # or throw
} # catch

sub then ($$$) {
  my ($promise, $onfulfilled, $onrejected) = @_;
  die TypeError 'The context object is not a promise'
      unless is_promise $promise;
  $onfulfilled = 'identity'
      if not defined $onfulfilled or not ref $onfulfilled eq 'CODE';
  $onrejected = 'thrower'
      if not defined $onrejected or not ref $onrejected eq 'CODE';
  my $promise_capability = new_promise_capability ref $promise; # or throw
  my $fulfill_reaction = {capabilities => $promise_capability,
                          handler => $onfulfilled};
  my $reject_reaction = {capabilities => $promise_capability,
                         handler => $onrejected};
  if ($promise->{promise_state} eq 'pending') {
    push @{$promise->{promise_fulfill_reactions}}, $fulfill_reaction;
    push @{$promise->{promise_reject_reactions}}, $reject_reaction;
  } elsif ($promise->{promise_state} eq 'fulfilled') {
    enqueue_promise_reaction_job $fulfill_reaction, $promise->{promise_result};
  } elsif ($promise->{promise_state} eq 'rejected') {
    enqueue_promise_reaction_job $reject_reaction, $promise->{promise_result};
  }
  return $promise_capability->{promise};
} # then

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
