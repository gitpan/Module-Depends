use strict;
package Module::Depends;
use Carp qw( croak );
use YAML qw( LoadFile );
use Cwd qw( getcwd );
use base qw( Class::Accessor::Chained );
use File::chdir;
__PACKAGE__->mk_accessors(qw( dist_dir debug libs requires build_requires ));
our $VERSION = '0.02';

=head1 NAME

Module::Depends - identify the dependencies of a distribution

=head1 SYNOPSIS

 use YAML;
 use Module::Depends;
 my $deps = Module::Depends->new->dist_dir( '.' )->find_modules;
 print "Our dependencies:\n", Dump { $depends->requires };

=head1 DESCRIPTION

Module::Depends extracts module dependencies from an unpacked
distribution tree.

Module::Depends only evaluates the META.yml shipped with a
distribution.  This won't be effective until all distributions ship
META.yml files, so we suggest you take your life in your hands and
look at Module::Depends::Intrusive.

=head1 METHODS

=head2 new

simple constructor

=cut

sub new {
    my $self = shift;

    return $self->SUPER::new({
        libs           => [],
        requires       => {},
        build_requires => {},
    });
}

=head2 dist_dir

Path where the distribution has been extracted to.

=head2 find_modules

scan the C<dist_dir> to populate C<libs>, C<requires>, and C<build_requires>

=cut

sub find_modules {
    my $self = shift;

    my $going_to = File::Spec->rel2abs( $self->dist_dir );
    local $CWD = $going_to;
    croak "couldn't chdir to " . $self->dist_dir . ": $!"
      unless $CWD eq $going_to;

    $self->_find_modules;
    return $self;
}

sub _find_modules {
    my $self = shift;

    my $file = File::Spec->catdir( $self->dist_dir, 'META.yml' );
    if (-e $file) {
        my $meta = LoadFile( $file );
        $self->requires( $meta->{requires} );
        $self->build_requires( $meta->{build_requires} );
    }
    return $self;
}


1;
__END__

=head2 libs

an array reference of lib lines

=head2 requires

A reference to a hash enumerating the prerequisite modules for this
distribution.

=head2 build_requires

A reference to a hash enumerating the modules needed to build the
distribution.

=head1 AUTHOR

Richard Clamp, based on code extracted from the Fotango build system
originally by James Duncan and Arthur Bergman.

=head1 COPYRIGHT

Copyright 2004 Fotango.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Module::Depends::Intrusive>

=cut
