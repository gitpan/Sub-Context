package Sub::Context;

use strict;

use vars qw( $VERSION );
$VERSION = '0.02';

my %allowed = map { $_ => 1 } qw( list void scalar );

sub import {
	my $class = shift;
	my $pkg = caller();

	while (@_) {
		my $subname = $pkg . '::' . shift;

		if (UNIVERSAL::isa($_[0], 'HASH')) {
			my $contexts = shift;

			foreach my $provided (keys %$contexts) {
				unless (exists $allowed{$provided}) {
					require Carp;
					Carp::carp "Context type '$provided' not allowed!";
				}
			}

			if (defined &$subname) {
				for (qw( void list scalar )) {
					$contexts->{$_} = \&$subname 
						unless defined $contexts->{$_};
				}

				replace_glob($subname);
			}

			no strict 'refs';
			*{ $subname } = sub {
				my $context = wantarray();
				$context = (defined $context) ?
					($context ? 'list' : 'scalar') :
					'void';

				my $error = "No sub for $context context";
				if (exists $contexts->{$context}) {
					my $sub = $contexts->{$context};
					if (defined &$sub) {
						goto &$sub;
					} else {
						$error .= ": $sub";
					}
				}
				require Carp;
				Carp::croak	$error;
			};
		}
	}
}

sub replace_glob {
	my $glob = shift;
	local *NEWGLOB;

	no strict 'refs';
	foreach my $slot (qw ( SCALAR ARRAY FORMAT IO HASH ) ) {
		if (defined *{ $glob }{$slot}) {
			*NEWGLOB = *{ $glob }{$slot};
		}
	}
	*{ $glob } = *NEWGLOB;
}

'your message here, contact $AUTHOR for rates';

__END__
=head1 NAME

Sub::Context - Perl extension to dispatch subroutines based on their calling
context

=head1 SYNOPSIS

	use Sub::Context sensitive => {
		void	=> \&whine,
		scalar	=> \&cry,
		list	=> \&weep,
	};

=head1 DESCRIPTION

Sub::Context automagically dispatches subroutine calls based on their calling
context.  This can be handy for converting return values or for throwing
warnings or even fatal errors.  For example, you can prohibit a function from
being called in void context.  Instead of playing around with C<wantarray()> on
your own, it's handled automatically.

=head2 EXPORT

None by default.  Simply C<use> the module and its custom C<import()> function
will handle things nicely for you.

=head1 IMPORTING

By convention, Sub::Context takes a list of arguments in pairs.  The first item
is always considered to be the name of a subroutine.  The second item in the
list is a reference to a hash of options for that subroutine.  For example, to
create a new sub, in the calling package, named C<penguinize>, with three
existing subroutines for each of the three types of context (void, list, and
scalar), write:

	use Sub::Context
		penguinize => {
			void	=> \&void_penguinize,
			list	=> \&list_penguinize,
			scalar	=> \&scalar_penguinize,
		};

You can provide your own subroutine references, of course:

	use Sub::Context
		daemonize => {
			list => sub { paint_red( penguinize() ) },
		};

If you are creating a new subroutine and do not provide a subroutine reference
for a context type, Sub::Context will helpfully C<croak()> when you call the
sub with the unsupported context.  You can also provide a scalar instead of a
subref, which will be appended to the error message:

	use Sub::Context 
		daemonize => {
			list => sub { paint_red( penguinize(@_) ) },
			void => 'daemons get snippy in void context',
		};

You're not limited to creating new subs.  You can wrap existing subs, as well.  
In this release, they must be in the calling package, but this may be fixed in
a future version.  Note that in this case, if you do not provide a new behavior
for a context type, the old behavior will be preserved.  For example, if you
have an existing sub that returns a string of words, you can say:

	use Sub::Context
		get_sentence => {
			list => sub { split(' ', get_sentence(@_) },
			void => 'results too good to throw away',
		};

Called in scalar context, C<get_sentence()> will behave like it always had.  In
list context, it will return a list of words (for whatever definition of
'words' the regex provides).  In void context, it will croak with the provided
error message.

=head1 TODO

=over 4

=item Add optional support for C<Want> (very soon)

=item Wrap subs in other packages

=item Allow unwrapping of wrapped subs (localized?)

=item World domination?

=back

=head1 HISTORY

=over 8

=item 0.02

Validate context types as suggested by Ben Tilly.

=item 0.01

Original version; created by h2xs 1.21 with options

  -C
	-A
	-X
	-n
	Sub::Context

=back

=head1 AUTHOR

chromatic, E<lt>chromatic@wgz.orgE<gt>

Other suggestions helpfully provided by thpfft, RhetTbull, and TheDamian on
Perlmonks.org.

=head1 COPYRIGHT

Copyright 2001 by chromatic.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=head1 SEE ALSO

L<perl>, C<wantarray>, C<Class::Multimethods>.

=cut
