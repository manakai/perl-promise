package Test::Dies;
use strict;
use warnings;
use Carp;
use Test::More;

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

push @EXPORT, qw(dies_ok);
## Derived from
## <https://github.com/wakaba/perl-test-moremore/blob/master/lib/Test/MoreMore.pm>.
sub dies_ok (&;$) {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($code, $name) = @_;
  #local $@ = undef;
  eval {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $code->();
    ok 0, $name;
    1;
  } or do {
    ok 1, $name || do { my $v = $@; $v =~ s/\n$//; $v };
  };
} # dies_ok

push @EXPORT, qw(dies_here_ok);
## Derived from
## <https://github.com/wakaba/perl-test-moremore/blob/master/lib/Test/MoreMore.pm>.
sub dies_here_ok (&;$) {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($code, $name) = @_;
  #local $@ = undef;
  eval {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $code->();
    ok 0, $name;
    1;
  } or do {
    my $caller_file = [caller(0)]->[1];
    my $caller_line = [caller(0)]->[2];
    my $pattern = ' at ' . (quotemeta $caller_file) . ' line ('
        . (join '|', ($caller_line - 10) .. $caller_line)
        . ')\.?$';
    like $@, qr{$pattern}, $name || do { my $v = $@; $v =~ s/\n$//; $v };
  };
} # dies_here_ok

1;

=head1 LICENSE

Copyright 2010-2011 Hatena <http://www.hatena.ne.jp/>.

Copyright 2011-2012 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
