use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Test::Dies;
use Promise;

{
  package test::package;
  use Carp;
  our @CARP_NOT = qw(Promise);
  $Promise::CreateTypeError = sub {
    return bless {message => $_[1], location => Carp::shortmess}, 'test::TypeError';
  };
}

test {
  my $c = shift;
  dies_ok {
    Promise->new;
  };
  isa_ok $@, 'test::TypeError';
  is $@->{message}, 'The executor is not a code reference';
  like $@->{location}, qr{ at \Q@{[__FILE__]}\E line \Q@{[__LINE__-4]}\E};
  done $c;
} n => 4, name => 'new with no args';

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
