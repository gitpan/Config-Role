use strict;
use warnings;

package Config::Role;
{
  $Config::Role::VERSION = '0.0.1';
}
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Moose config attribute loaded from file in home dir

use File::HomeDir;
use Path::Class::Dir;
use Path::Class::File;
use Config::Any;
use MooseX::Types::Moose qw(ArrayRef HashRef Str Object);

use MooseX::Types -declare => [qw( File ArrayRefOfFile )];
subtype File,
    as Object,
    where { $_->isa('Path::Class::File') };
coerce File,
    from Str,
    via { Path::Class::File->new($_) };
subtype ArrayRefOfFile,
    as ArrayRef[File];
coerce ArrayRefOfFile,
    from ArrayRef[Str],
    via { [ map { to_File($_) } @$_ ] };


requires 'config_filename';


has 'config_file' => (
    is         => 'ro',
    isa        => File,
    coerce     => 1,
    lazy_build => 1,
);

sub _build_config_file {
    my ($self) = @_;
    my $home = File::HomeDir->my_data;
    my $conf_file = Path::Class::Dir->new($home)->file(
        $self->config_filename
    );
    return $conf_file;
}


has 'config_files' => (
    is         => 'ro',
    isa        => ArrayRefOfFile,
    coerce     => 1,
    lazy_build => 1,
);
sub _build_config_files {
    my ($self) = @_;
    return [ $self->config_file ];
}


has 'config' => (
    is         => 'ro',
    isa        => HashRef,
    lazy_build => 1,
);

sub _build_config {
    my ($self) = @_;
    my $cfg = Config::Any->load_files({
        use_ext => 1,
        files   => $self->config_files,
    });
    foreach my $config_entry ( @{ $cfg } ) {
        my ($filename, $config) = %{ $config_entry };
        return $config;
    }
    return {};
}

1;



=pod

=encoding utf-8

=head1 NAME

Config::Role - Moose config attribute loaded from file in home dir

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    package My::Class;
    use Moose;

    # Read configuration from ~/.my_class.ini, available in $self->config
    has 'config_filename' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
    sub _build_config_filename { '.my_class.ini' }
    with 'Config::Role';

    # Fetch a value from the configuration, allow constructor override
    has 'username' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
    sub _build_username { return (shift)->config->{'username'}; }

    sub make_request {
        my ($self) = @_;
        my $response = My::Class::Request->make(
            username => $self->username,
            ...
        );
        ...
    }

=head1 DESCRIPTION

Config::Role is a very basic role you can add to your Moose class that
allows it to take configuration data from a file located in your home
directory instead of always requiring parameters to be specified in the
constructor.

The synopsis shows how you can read the value of C<username> from the file
C<.my_class.ini> located in the home directory of the current user.  The
location of the file is determined by whatever C<< File::HomeDir->my_data >>
returns for your particular platform.

The config file is loaded by using L<Config::Any>'s C<load_files()> method.
It will load the files specified in the C<config_files> attribute.  By
default this is an array reference that contains the filename from the
C<config_file> attribute.  If you specify multiple files which both contain
the same configuration key, the value is loaded from the first file.  That
is, the most significant file should be first in the array.

The C<< Config::Any->load_files() >> flag C<use_ext> is set to a true value, so you
can use any configuration file format supported by L<Config::Any> by just
specifying the common filename extension for the format.

=head1 ATTRIBUTES

=head2 config_file

The filename the configuration is read from. A Path::Class::File object.
Allows coercion from Str.

=head2 config_files

The collection of filenames the configuration is read from. Array reference
of L<Path::Class::File> objects.  Allows coercion from an array reference of
strings.

=head2 config

A hash reference that holds the compiled configuration read from the
specified files.

=head1 METHODS

=head2 config_filename

Required method on the composing class. Should return a string with the name
of the configuration file name.

=head1 SEMANTIC VERSIONING

This module uses semantic versioning concepts from L<http://semver.org/>.

=head1 SEE ALSO

=over 4

=item *

L<Moose>

=item *

L<File::HomeDir>

=item *

L<Config::Any>

=item *

L<Path::Class::File>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Config::Role

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Config-Role>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Role>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annonations of Perl module documentation.

L<http://annocpan.org/dist/Config-Role>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Config-Role>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Config-Role>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Config-Role>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Config-Role>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual way to determine what Perls/platforms PASSed for a distribution.

L<http://matrix.cpantesters.org/?dist=Config-Role>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Config::Role>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-config-role at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Role>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/robinsmidsrod/Config-Role>

  git clone git://github.com/robinsmidsrod/Config-Role.git

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

