#!/usr/bin/perl -w
use strict;

chdir 't' if -d 't';
unshift @INC, '../blib/lib';

use Test::More 'no_plan';

use vars qw( $void_called $anormalsub %anormalsub @anormalsub );

# see if it can be compiled and called
use_ok( 'Sub::Context' );

Sub::Context->import( 
	foo => {
		void	=> \&void,
		list	=> \&list,
		scalar	=> \&scalar,
	}
);

can_ok( 'main', 'foo' );

foo();
ok( $void_called, 'should detect and dispatch in void context' );
my @list = foo();
is( scalar @list, 2, 'should respect list context' );
is( join(' ', @list), 'list called', '... and should return correct order' );
is( foo(), 'scalar called', 'should detect and dispatch in scalar context' );

package NotMain;

Sub::Context->import(
	bar => {
		list	=> \&list,
		scalar	=> 'not a sub',
	},
);

package main;

can_ok('NotMain', 'bar' );
ok( !( UNIVERSAL::can('main', 'bar' )), 
	'import should only pollute calling package namespace' );

eval { NotMain::bar() };
like( $@, '/No sub for void/', 'should warn with unexpected context' );
eval { my $foo = NotMain::bar() };
like( $@, '/No sub for scalar/', 'should not attempt to call a non-sub' );
like( $@, '/not a sub/', 'should warn with custom message, if necessary' );

$anormalsub = 100;
%anormalsub = ( sunny => 'ataraxic' );
@anormalsub = ( 'kudra' );

Sub::Context->import(
	anormalsub => {
		void	=> sub { die "No void allowed!" },
		list	=> sub { split(' ', anormalsub()) },
	},
);

is( $anormalsub, 100, 'should not overwrite existing scalar slot' );
is( $anormalsub{sunny}, 'ataraxic', '... hash slot' );
is( $anormalsub[0], 'kudra', '... array slot' );
is( anormalsub(), 'this is a normal sub', 'should not override original subs' );
my @words = anormalsub();
is( scalar @words, 5, 'should wrap around existing sub for context' );
is( join(' ', @words), 'this is a normal sub', 'should call passed subref' );

{
	my $warn;
	local $SIG{__WARN__} = sub {
		$warn = shift;
	};
	Sub::Context->import(
		baz => {
			viod => sub {},
		},
	);
	like( $warn, "/type 'viod' not allowed/", 
		'import() should warn with bad type request' );
}

sub void {
	$void_called = 1;
}

sub list {
	my @array = ('list', 'called');
	return @array;
}

sub scalar {
	return 'scalar called'
}

sub anormalsub {
	return 'this is a normal sub';
}
