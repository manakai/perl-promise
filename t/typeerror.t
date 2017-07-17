use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Promise;

test {
  my $c = shift;
  eval {
    Promise->new;
  };
  isa_ok $@, 'Promise::TypeError';
  is $@->name, 'TypeError';
  is $@->message, 'The executor is not a code reference';
  is $@->file_name, __FILE__;
  is $@->line_number, __LINE__-6;
  is $@ . '', $@->name . ': ' . $@->message . " at " . $@->file_name . " line " . $@->line_number . ".\n";
  done $c;
} n => 6, name => 'throw TypeError';

test {
  my $c = shift;
  my $resolve;
  my $p = Promise->new (sub { $resolve = $_[0] });
  $resolve->($p);
  $p->catch (sub {
    my $e = $_[0];
    test {
      isa_ok $e, 'Promise::TypeError';
      is $e->name, 'TypeError';
      is $e->message, 'SelfResolutionError';
      is $e->file_name, __FILE__;
      is $e->line_number, __LINE__-8;
      is $e . '', $e->name . ': ' . $e->message . " at " . $e->file_name . " line " . $e->line_number . ".\n";
      done $c;
      undef $c;
    } $c;
  });
} n => 6, name => 'reject TypeError';

test {
  my $c = shift;
  ok $Web::DOM::Error::L1ObjectClass->{'Promise::TypeError'};
  done $c;
} n => 1, name => 'Perl Error Object Interface Level 1';

test {
  my $c = shift;

  my $error = new Promise::TypeError ('Error message');
  isa_ok $error, 'Promise::TypeError';

  is $error->name, 'TypeError';
  is $error->message, 'Error message';
  is $error->file_name, __FILE__;
  is $error->line_number, __LINE__-6;
  is $error . '', "TypeError: Error message at ".$error->file_name." line ".$error->line_number.".\n";

  done $c;
} name => 'with message', n => 6;

test {
  my $c = shift;

  my $error = new Promise::TypeError;
  is $error->name, 'TypeError';
  is $error->message, '';
  is $error->file_name, __FILE__;
  is $error->line_number, __LINE__-4;
  is $error . '', "TypeError at ".$error->file_name." line ".$error->line_number.".\n";
  is $error->stringify, $error . '';
  done $c;
} name => 'without message', n => 6;

test {
  my $c = shift;
  my $error1 = new Promise::TypeError ('hoge');
  my $error2 = new Promise::TypeError ('hoge');

  ok $error1 eq $error1;
  ok not $error1 ne $error1;
  ok not $error2 eq $error1;
  ok $error2 ne $error1;
  ok $error1 ne undef;
  ok not $error1 eq undef;
  is $error1 cmp $error1, 0;
  isnt $error1 cmp $error2, 0;
  isnt $error1 . '', $error1;
  
  done $c;
} name => 'eq', n => 9;

run_tests;

=head1 LICENSE

Copyright 2012-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
