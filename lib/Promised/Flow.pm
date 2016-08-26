package Promised::Flow;
use strict;
use warnings;
our $VERSION = '1.0';
use Carp;
use AnyEvent;
use Promise;

our @EXPORT;

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

push @EXPORT, qw(promised_cleanup);
sub promised_cleanup (&$) {
  my ($code, $p) = @_;
  return $p->then (sub {
    my $return = $_[0];
    return Promise->resolve->then ($code)->then (sub { return $return } );
  }, sub {
    my $error = $_[0];
    return Promise->resolve->then ($code)->then (sub { die $error }, sub { die $error });
  });
} # promised_cleanup

push @EXPORT, qw(promised_sleep);
sub promised_sleep ($) {
  my $sec = $_[0];
  return Promise->new (sub {
    my ($ok) = @_;
    my $timer; $timer = AE::timer $sec, 0, sub {
      $ok->();
      undef $timer;
    };
  });
} # promised_sleep

push @EXPORT, qw(promised_timeout);
sub promised_timeout (&$) {
  my ($code, $sec) = @_;
  return Promise->resolve->then ($code) unless defined $sec;
  return Promise->new (sub {
    my ($ok, $ng) = @_;
    my $timer; $timer = AE::timer $sec, 0, sub {
      $ng->("Timeout ($sec s)");
      undef $timer;
    };
    Promise->resolve->then ($code)->then (sub {
      my $result = $_[0];
      undef $timer;
      $ok->($result);
    }, sub {
      my $error = $_[0];
      undef $timer;
      $ng->($error);
    });
  });
} # promised_timeout

push @EXPORT, qw(promised_for);
sub promised_for (&$) {
  my ($code, $list) = @_;
  my $p = Promise->resolve;
  for my $item (@$list) {
    $p = $p->then (sub {
      return $code->($item);
    });
  }
  return $p->then (sub { return undef });
} # promised_for

push @EXPORT, qw(promised_wait_until);
sub promised_wait_until (&;%) {
  my ($code, %args) = @_;
  $args{interval} ||= 1;

  my $timer;
  my $try; $try = sub {
    return Promise->resolve->then ($code)->then (sub {
      if ($_[0]) {
        return;
      } else {
        return unless defined $try;
        ## Cancellable promise saves us...
        return Promise->new (sub {
          my ($ok) = @_;
          $timer = AE::timer $args{interval}, 0, sub {
            $ok->();
            undef $timer;
          };
        })->then (sub {
          return $try->() if defined $try;
        });
      }
    });
  }; # $try

  return promised_cleanup {
    undef $try;
    undef $timer;
  } promised_timeout {
    return $try->();
  } $args{timeout};
} # promised_wait_until

1;
