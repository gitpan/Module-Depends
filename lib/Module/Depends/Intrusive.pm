use strict;
package Module::Depends::Intrusive;
use base qw( Module::Depends );
use Carp qw( croak );
use ExtUtils::MakeMaker ();

sub _find_modules {
    my $self = shift;

    # fake up Module::Build and ExtUtils::MakeMaker
    no warnings 'redefine';
    local $INC{"Module/Build.pm"} = 1;
    local *STDIN; # run non-interactive
    local *ExtUtils::Liblist::ext = sub {
        my ($class, $lib) = @_;
        $lib =~ s/\-l//;
        push @{ $self->libs }, $lib;
        return 1;
    };
    local *CORE::GLOBAL::exit = sub { goto _exit };
    local *Module::Build::new = sub {
        my $class = shift;
        my %args =  @_;
        $self->requires( $args{requires} || {} );
        $self->build_requires( $args{build_requires} || {} );
        return bless {}, 'Module::Build';
    };
    local *Module::Build::create_build_script = sub { 1 };
    local *main::WriteMakefile;
    local *ExtUtils::MakeMaker::WriteMakefile = sub {
      my %args = @_;
      $self->requires( $args{PREREQ_PM} || {} );
      return 1;
    };

    # this order is important, as when a Makefile.PL and Build.PL are
    # present, the Makefile.PL could just be a passthrough
    my $file = -e 'Build.PL' ? 'Build.PL' : -e 'Makefile.PL' ? 'Makefile.PL' :
      croak "No {Build,Makefile}.PL found in '".$self->dist_dir."'\n";
    $file = $self->dist_dir . "/$file";
    eval {
        package main;
        require "$file";
      _exit:
        delete $INC{$file};
    };
    die $@ if $@;
    return $self;
}

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
