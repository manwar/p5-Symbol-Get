package Symbol::Get;

use strict;
use warnings;

use Call::Context ();

our $VERSION = 0.02;

=encoding utf-8

=head1 NAME

Symbol::Get - Read Perl’s symbol table programmatically

=head1 SYNOPSIS

    package Foo;

    our $name = 'haha';
    our @list = ( 1, 2, 3 );
    our %hash = ( foo => 1, bar => 2 );

    sub doit { ... }

    my $name_sr = Symbol::Get::get('$Foo::name');    # \$name
    my $list_ar = Symbol::Get::get('$Foo::list');    # \@list
    my $hash_hr = Symbol::Get::get('$Foo::hash');    $ \%hash

    #Defaults to __PACKAGE__ if none is given:
    my $doit_cr = Symbol::Get::get('&doit');

    #The below return the same results since get_names() defaults
    #to the current package if none is given.
    my @names = Symbol::Get::get_names('Foo');      # keys %Foo::
    my @names = Symbol::Get::get_names();

=head1 DESCRIPTION

Occasionally I have need to reference a variable programmatically.
This module facilitates that by providing an easy, syntactic-sugar-y,
read-only interface to the symbol table.

The SYNOPSIS above should pretty well cover usage.

=head1 SEE ALSO

=over 4

=item * L<Symbol::Values>

=back

=head1 LICENSE

This module is licensed under the same license as Perl.

=cut

my %_sigil_to_type = qw(
    $   SCALAR
    @   ARRAY
    %   HASH
    &   CODE
);

my $sigils_re_txt = join('|', keys %_sigil_to_type);

sub get {
    my ($var) = @_;

    die 'Need a variable name!' if !length $var;

    my $sigil = substr($var, 0, 1);

    my $type = $_sigil_to_type{$sigil} or die "Unrecognized sigil: “$sigil”";

    my $table_hr = _get_table_hr( substr($var, 1) );
    return $table_hr && *{$table_hr}{$type};
}

sub get_names {
    my ($module) = @_;

    $module ||= (caller 0)[0];

    Call::Context::must_be_list();

    my $table_hr = _get_module_table_hr($module);

    die "Unknown namespace: “$module”" if !$table_hr;

    return keys %$table_hr;
}

#----------------------------------------------------------------------
# To be completed if needed:
#
#sub list_sigils {
#    my ($full_name) = @_;
#
#    Call::Context::must_be_list();
#
#    my ($module, $name) = ($full_name =~ m<(?:(.+)::)?(.+)>);
#
#    my $table_hr = _get_table_for_module_name($module);
#    my $glob = *{$table_hr};
#
#    return
#}
#


#----------------------------------------------------------------------

sub _get_module_table_hr {
    my ($module) = @_;

    my @nodes = split m<::>, $module;

    my $table_hr = \%main::;

    my $pkg = q<>;

    for my $n (@nodes) {
        $table_hr = $table_hr->{"$n\::"};
        $pkg .= "$n\::";
    }

    return $table_hr;
}

sub _get_table_hr {
    my ($name) = @_;

    $name =~ m<\A (?: (.+) ::)? ([^:]+ (?: ::)?) \z>x or do {
        die "Invalid variable name: “$name”";
    };

    my $module = $1 || (caller 1)[0];

    my $table_hr = _get_module_table_hr($module);

    return $table_hr->{$2};
}

1;
