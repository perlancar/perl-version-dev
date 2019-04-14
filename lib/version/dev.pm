package version::dev;

# DATE
# VERSION

use strict 'subs', 'vars';
use warnings;

use Cwd qw(abs_path);
use Module::Path::More qw(module_path);
use Versioning::Scheme::Perl;

sub import {
    unshift @INC, __PACKAGE__->new;
}

sub new {
    my $class = shift;
    bless {}, $class;
}

sub version::dev::INC {
    my ($self, $filename) = @_;

    # load module from filesystem
    my $path = module_path(module => $filename) or return undef;
    { local @INC = grep { !ref || $_ != $self } @INC; require $filename }

    # check if the module source file is inside current working directory
    return \1 unless index(abs_path($path), abs_path(".")) >= 0;

    # check if package defines $VERSION
    (my $pkg = $filename) =~ s!/!::!g; $pkg =~ s/\.pm\z//;
    return \1 if defined ${"$pkg\::VERSION"};

    # get the most recent version tag from git
    my $found;
    for my $tag (`git tag`) {
        chomp $tag;
        Versioning::Scheme::Perl->is_valid_version($tag) or next;
        ${"$pkg\::VERSION"} = Versioning::Scheme::Perl->bump_version(
            $tag, {part=>'dev'});
        return \1;
    }
    die "Cannot find any version in `git tag`";
}

1;
# ABSTRACT: Set $VERSION based on version from git tags

=for Pod::Coverage .+

=head1 SYNOPSIS

In F<lib/MyModule.pm> you work on (you're using L<Dist::Zilla> and a plugin like
L<Dist::Zilla::Plugin::PkgVersion> or L<Dist::Zilla::Plugin::OurPkgVersion>):

 package MyModule;
 # VERSION
 ...

Your git tags:

 % git tag
 v0.003
 v0.002
 v0.001

When running script that uses your module:

 % perl -Ilib -Mversion::dev -MMyModule E'...'

C<$MyModule::VERSION> will be set to C<0.003_001> (if not already set).


=head1 DESCRIPTION

Sometimes you do not explicitly set C<$VERSION> in the module source code that
you're working on. For example, you're using L<Dist::Zilla> with a plugin that
will set C<$VERSION> during build, so only your built version of modules will
have their C<$VERSION> set. When using the unbuilt version, this sometimes
creates problem or annoyances when other modules or other code expect your
module to set C<$VERSION>.

This pragma solves that annoyances. It installs a require hook that will check
if the module being loaded is: 1) inside the working directory; and 2) the
module's package does not have C<$VERSION> set.

If the conditions are met, then first it will: 1) execute C<git tag> to list
tags that look like a version number; 2) grab the most recent version; 3) bump
the version's dev part, e.g. v1.1 becomes v1.1_001 and v1.1_001 becomes
v1.1_002; 3) set the module's package C<$VERSION> with this version.


=head1 SEE ALSO
