package Promised::Flow;
use strict;
use warnings;
our $VERSION = '4.0';
use Carp;
use AnyEvent;
use Promise;
use Promise::AbortError;
use AbortController;

our @EXPORT;
push our @CARP_NOT, qw(Promise Promise::AbortError);

sub import ($;@) {
  my $from_class = shift;
  my ($to_class, $file, $line) = caller;
  no strict 'refs';
  for (@_ ? @_ : @{$from_class . '::EXPORT'}) {
    my $code = $from_class->can ($_)
        or croak qq{"$_" is not exported by the $from_class module at $file line $line};
    *{$to_class . '::' . $_} = $code;
  }
} # import

BEGIN {
  my $pr = Promise->resolve;
  eval q{ use constant PR => $pr };
  $pr->{is_global_variable} = 1;
  undef $pr;
}

push @EXPORT, qw(promised_cleanup);
sub promised_cleanup (&$) {
  my ($code, $p) = @_;
  return $p->then (sub {
    my $return = $_[0];
    return PR->then ($code)->then (sub { return $return } );
  }, sub {
    my $error = $_[0];
    return PR->then ($code)->then (sub { die $error }, sub { die $error });
  });
} # promised_cleanup

push @EXPORT, qw(promised_sleep);
sub promised_sleep ($;%) {
  my ($sec, %args) = @_;
  my $aborted = sub { };
  if (defined $args{signal}) {
    if ($args{signal}->aborted) {
      if (defined $args{name}) {
        return Promise->reject (Promise::AbortError->new ("Aborted by signal - $args{name}"));
      } else {
        return Promise->reject (Promise::AbortError->new ('Aborted by signal'));
      }
    } else {
      $args{signal}->manakai_onabort (sub {
        $aborted->();
      });
    }
  }
  return Promise->new (sub {
    my ($ok, $ng) = @_;
    my $timer;
    $aborted = sub {
      undef $timer;
      $ng->(Promise::AbortError->new ('Aborted by signal'));
      $aborted = $ok = $ng = sub { };
    };
    $timer = AE::timer $sec, 0, sub {
      undef $timer;
      $ok->();
      $aborted = $ok = $ng = sub { };
    };
  });
} # promised_sleep

push @EXPORT, qw(promised_timeout);
sub promised_timeout (&$;%) {
  my ($code, $sec, %args) = @_;
  my $suffix = defined $args{name} ? " - $args{name}" : "";
  my $aborted = sub { };
  if (defined $args{signal}) {
    if ($args{signal}->aborted) {
      return Promise->reject (Promise::AbortError->new ('Aborted by signal' . $suffix));
    } else {
      $args{signal}->manakai_onabort (sub {
        $aborted->();
      });
    }
  }
  return PR->then ($code) unless defined $sec;
  return Promise->new (sub {
    my ($ok, $ng) = @_;
    my $to = Promise::AbortError->new ("Timeout ($sec s)$suffix");
    my $timer; $timer = AE::timer $sec, 0, sub {
      $ng->($to);
      undef $timer;
      $aborted = $ok = $ng = sub { };
    };
    $aborted = sub {
      undef $timer;
      $ng->(Promise::AbortError->new ('Aborted by signal' . $suffix));
      $aborted = $ok = $ng = sub { };
    };
    PR->then ($code)->then (sub {
      my $result = $_[0];
      undef $timer;
      $ok->($result);
      $aborted = $ok = $ng = sub { };
    }, sub {
      my $error = $_[0];
      undef $timer;
      $ng->($error);
      $aborted = $ok = $ng = sub { };
    });
  });
} # promised_timeout

push @EXPORT, qw(promised_for);
sub promised_for (&$) {
  my ($code, $list) = @_;
  my $p = PR;
  for my $item (@$list) {
    $p = $p->then (sub {
      return $code->($item);
    });
  }
  return $p->then (sub { return undef });
} # promised_for

push @EXPORT, qw(promised_map);
sub promised_map (&$) {
  my ($code, $list) = @_;
  my $p = Promise->resolve;
  my $new_list = [];
  for my $item (@$list) {
    $p = $p->then (sub {
      return $code->($item);
    })->then (sub {
      push @$new_list, $_[0];
    });
  }
  return $p->then (sub { return $new_list });
} # promised_map

push @EXPORT, qw(promised_until);
sub promised_until (&;%) {
  my $cb = shift;
  my %args = @_;

  my ($f, $j);
  my $p = Promise->new (sub { ($f, $j) = @_ });

  my $iter; $iter = sub {
    if (defined $args{signal} and $args{signal}->aborted) {
      undef $iter;
      my $suffix = defined $args{name} ? " - $args{name}" : "";
      $j->(Promise::AbortError->new ('Aborted by signal' . $suffix));
      return undef;
    }
    PR->then ($cb)->then (sub {
      if ($_[0]) {
        undef $iter;
        $f->();
      } else {
        $iter->();
      }
      return undef;
    }, sub {
      undef $iter;
      $j->($_[0]);
    });
    return undef;
  }; # $iter
  $iter->();

  return $p;
} # promised_until

push @EXPORT, qw(promised_wait_until);
sub promised_wait_until (&;%) {
  my ($code, %args) = @_;
  $args{interval} ||= 1;

  my $ac1 = AbortController->new;
  my $ac2 = AbortController->new;
  if (defined $args{signal}) {
    $args{signal}->manakai_onabort (sub {
      $ac1->abort;
      $ac2->abort;
    });
  }

  my $timer;
  return ((promised_timeout {
    return promised_until {
      return PR->then ($code)->then (sub {
        return 'done' if $_[0];
        return promised_sleep ($args{interval}, signal => $ac1->signal, name => $args{name})->then (sub {
          return not 'done';
        });
      });
    } signal => $ac2->signal, name => $args{name};
  } $args{timeout}, name => $args{name})->finally (sub {
    $ac1->abort;
    $ac2->abort;
    $args{signal}->manakai_onabort (undef) if defined $args{signal};
    undef $timer;
  }));
} # promised_wait_until

push @EXPORT, qw(promised_cv);
sub promised_cv () {
  my ($send, $croak);
  my $receive = Promise->new (sub { ($send, $croak) = @_ });
  return ($receive, $send, $croak);
} # promised_cv

1;

=head1 LICENSE

Copyright 2016-2022 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
