use strict;
package Module::Depends::Intrusive;
use base qw( Module::Depends );
use Cwd qw( getcwd );
use ExtUtils::MakeMaker ();

sub _find_modules {
    my $self = shift;

    # this order is important, as when a Makefile.PL and Build.PL are
    # present, the Makefile.PL could just be a passthrough
    my $pl = -e 'Build.PL' ? 'Build.PL' : -e 'Makefile.PL' ? 'Makefile.PL' : 0;
    unless ($pl) {
        $self->error( 'No {Build,Makefile}.PL found in '.$self->dist_dir );
        return $self;
    }

    # fake up Module::Build and ExtUtils::MakeMaker
    no warnings 'redefine';
    local *STDIN; # run non-interactive
    local *ExtUtils::Liblist::ext = sub {
        my ($class, $lib) = @_;
        $lib =~ s/\-l//;
        push @{ $self->libs }, $lib;
        return 1;
    };
    local *CORE::GLOBAL::exit = sub { };
    local $INC{"Module/Build.pm"} = 1;
    local *Module::Build::new = sub {
        my $class = shift;
        my %args =  @_;
        $self->requires( $args{requires} || {} );
        $self->build_requires( $args{build_requires} || {} );
        bless {}, "Module::Depends::Intrusive::Fake::Module::Build";
    };
    local *Module::Build::subclass = sub { 'Module::Build' };
    local $Module::Build::VERSION = 666;

    my $WriteMakefile = sub {
        my %args = @_;
        $self->requires( $args{PREREQ_PM} || {} );
        1;
    };
    local *main::WriteMakefile;
    local *ExtUtils::MakeMaker::WriteMakefile = $WriteMakefile;

    # Inline::MakeMaker
    local $INC{"Inline/MakeMaker.pm"} = 1;

    local @Inline::MakeMaker::EXPORT = qw( WriteMakefile WriteInlineMakefile );
    local @Inline::MakeMaker::ISA = qw( Exporter );
    local *Inline::MakeMaker::WriteMakefile = $WriteMakefile;
    local *Inline::MakeMaker::WriteInlineMakefile = $WriteMakefile;

    # Module::Install
    local $INC{"inc/Module/Install.pm"} = 1;
    local @inc::Module::Install::ISA = qw( Exporter );
    local @inc::Module::Install::EXPORT = qw( AUTOLOAD requires build_requires );
    local *inc::Module::Install::AUTOLOAD = sub { 1 };
    local *inc::Module::Install::requires = sub {
        my ($module, $version) = @_;
        $version ||= 0;
        $self->requires->{$module} = $version;
    };
    local *inc::Module::Install::build_requires = sub {
        my ($module, $version) = @_;
        $version ||= 0;
        $self->build_requires->{$module} = $version;
    };

    my $file = File::Spec->catfile( getcwd(), $pl );
    eval {
        package main;
        no strict;
        no warnings;
        require "$file";
    };
    $self->error( $@ ) if $@;
    delete $INC{$file};
    return $self;
}

package Module::Depends::Intrusive::Fake::Module::Build;
sub DESTROY {}
sub AUTOLOAD { shift }

1;

__END__

=head1 NAME

Module::Depends::Intrusive - intrusive discovery of distribution dependencies.

=head1 SYNOPSIS

 # Just like Module::Depends, only use the Intrusive class instead

=head1 DESCRIPTION

This module devines dependencies by running the distributions
Makefile.PL/Build.PL in a faked up environment and intercepting the
calls to Module::Build->new and ExtUtils::MakeMaker::WriteMakefile.

You may now freak out about security.

While you're doing that please remember that what we're doing is much
the same that CPAN.pm does in order to discover prerequisites.

=head1 AUTHOR

Richard Clamp, based on code extracted from the Fotango build system
originally by James Duncan and Arthur Bergman.

=head1 COPYRIGHT

Copyright 2004 Fotango.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Module::Depends>

=cut