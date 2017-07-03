use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Promise;

my @Reject;
my @Handle;
$Promise::RejectionTrackerReject = sub {
  push @Reject, $_[0]
};
$Promise::RejectionTrackerHandle = sub {
  push @Handle, $_[0]
};

test {
  my $c = shift;
  my $p = Promise->reject;
  Promise->resolve->then (sub {
    my @reject = grep { $_ eq $p } @Reject;
    my @handle = grep { $_ eq $p } @Handle;
    test {
      is 0+@reject, 1;
      is 0+@handle, 0;
    } $c;
    done $c;
    undef $c;
  });
} n => 2, name => 'rejected unhandled';

test {
  my $c = shift;
  my $p = Promise->reject->catch (sub { });
  Promise->resolve->then (sub {
    my @reject = grep { $_ eq $p } @Reject;
    my @handle = grep { $_ eq $p } @Handle;
    test {
      is 0+@reject, 0;
      is 0+@handle, 0;
    } $c;
    done $c;
    undef $c;
  });
} n => 2, name => 'rejected handled';

test {
  my $c = shift;
  my $p = Promise->resolve;
  Promise->resolve->then (sub {
    my @reject = grep { $_ eq $p } @Reject;
    my @handle = grep { $_ eq $p } @Handle;
    test {
      is 0+@reject, 0;
      is 0+@handle, 0;
    } $c;
    done $c;
    undef $c;
  });
} n => 2, name => 'resolved';

test {
  my $c = shift;
  my $p = Promise->reject;
  $p->catch (sub { });
  $p->catch (sub { });
  Promise->resolve->then (sub {
    my @reject = grep { $_ eq $p } @Reject;
    my @handle = grep { $_ eq $p } @Handle;
    test {
      is 0+@reject, 1;
      is 0+@handle, 1;
    } $c;
    done $c;
    undef $c;
  });
} n => 2, name => 'rejected then handled';

test {
  my $c = shift;
  my $reject;
  my $p = Promise->new (sub { $reject = $_[1] });
  $p->then->catch (sub { });
  $reject->();
  Promise->resolve->then (sub {
    my @reject = grep { $_ eq $p } @Reject;
    my @handle = grep { $_ eq $p } @Handle;
    test {
      is 0+@reject, 0;
      is 0+@handle, 0;
    } $c;
    done $c;
    undef $c;
  });
} n => 2, name => 'handled then rejected';

run_tests;

@Reject = ();
@Handle = ();

=head1 LICENSE

Copyright 2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

