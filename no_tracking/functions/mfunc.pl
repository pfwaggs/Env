#!/usr/bin/env perl

# vim: ai si sw=4 sts=4 et

# normal junk #AAA
use warnings;
use strict;
use v5.22;
use experimental qw(postderef signatures smartmatch);

#ZZZ

chomp (my @list = qx[grep  '() ' *]);

@list = map {/^(\w+:\w+ )/} @list;
my %list;
for (@list) {
    my ($k,$v) = split /:/, $_;
    $k =~ s/^\s+|\s+$//g;
    $v =~ s/^\s+|\s+$//g;
    push $list{$k}->@*, $v;
}
say join(' ',"$_:", $list{$_}->@*) for sort keys %list;

