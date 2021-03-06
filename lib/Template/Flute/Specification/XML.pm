package Template::Flute::Specification::XML;

use strict;
use warnings;

use XML::Twig;

use Template::Flute::Specification;

=head1 NAME

Template::Flute::Specification::XML - XML Specification Parser

=head1 SYNOPSIS

    $xml = new Template::Flute::Specification::XML;

    $spec = $xml->parse_file($specification_file);
    $spec = $xml->parse($specification_text);

=head1 CONSTRUCTOR

=head2 new

Create a Template::Flute::Specification::XML object.

=cut

# Constructor

sub new {
	my ($class, $self);
	my (%params);

	$class = shift;
	%params = @_;

	$self = \%params;
	bless $self;
}

=head1 METHODS

=head2 parse [ STRING | SCALARREF ]

Parses text from STRING or SCALARREF and returns L<Template::Flute::Specification>
object in case of success.

=cut

sub parse {
	my ($self, $text) = @_;
	my ($twig, $xml);

	$twig = $self->_initialize;

	if (ref($text) eq 'SCALAR') {
		$xml = $twig->safe_parse($$text);
	}
	else {
		$xml = $twig->parse($text);
	}

	unless ($xml) {
		$self->_add_error(error => $@);
		return;
	}

	return $self->{spec};
}

=head2 parse_file STRING

Parses file and returns L<Template::Flute::Specification> object in
case of success.

=cut
	
sub parse_file {
	my ($self, $file) = @_;
	my ($twig, $xml);

	$twig = $self->_initialize;
	
	$xml = $twig->safe_parsefile($file);

	unless ($xml) {
		$self->_add_error(file => $file, error => $@);
		return;
	}

	return $self->{spec};
}

sub _initialize {
	my $self = shift;
	my (%handlers, $twig);
	
	# initialize stash
	$self->{stash} = [];
	
	# specification object
	$self->{spec} = new Template::Flute::Specification;

	# twig handlers
	%handlers = (specification => sub {$self->_spec_handler($_[1])},
 				 container => sub {$self->_container_handler($_[1])},
				 list => sub {$self->_list_handler($_[1])},
				 paging => sub {$self->_stash_handler($_[1])},
 				 filter => sub {$self->_stash_handler($_[1])},
				 form => sub {$self->_form_handler($_[1])},
				 param => sub {$self->_stash_handler($_[1])},
				 value => sub {$self->_value_handler($_[1])},
 				 field => sub {$self->_stash_handler($_[1])},
				 i18n => sub {$self->_i18n_handler($_[1])},
				 input => sub {$self->_stash_handler($_[1])},
				 sort => sub {$self->_sort_handler($_[1])},
				 );
	
	# twig parser object
	$twig = new XML::Twig (twig_handlers => \%handlers);

	return $twig;
}

sub _spec_handler {
	my ($self, $elt) = @_;
	my ($name);

	$name = $elt->att('name');
}

sub _container_handler {
	my ($self, $elt) = @_;
	my ($name, %container);
	
	$name = $elt->att('name');

	$container{container} = $elt->atts();
	
	# flush elements from stash into container hash
	$self->_stash_flush($elt, \%container);

	# add container to specification object
	$self->{spec}->container_add(\%container);
}

sub _list_handler {
	my ($self, $elt) = @_;
	my ($name, %list);
	
	$name = $elt->att('name');

	$list{list} = $elt->atts();
	
	# flush elements from stash into list hash
	$self->_stash_flush($elt, \%list);

	# add list to specification object
	$self->{spec}->list_add(\%list);
}

sub _sort_handler {
	my ($self, $elt) = @_;
	my (@ops, $name);

	$name = $elt->att('name');
	
	for my $child ($elt->children()) {
		if ($child->gi() eq 'field') {
			push (@ops, {type => 'field',
						 name => $child->att('name'),
						 direction => $child->att('direction')});
		}
		else {
			die "Invalid child for sort $name.\n";
		}
	}

	unless (@ops) {
		die "Empty sort $name.\n";
	}
	
	$elt->set_att('ops', \@ops);
	push @{$self->{stash}}, $elt;	
}

sub _stash_handler {
	my ($self, $elt) = @_;

	push @{$self->{stash}}, $elt;
}

sub _form_handler {
	my ($self, $elt) = @_;
	my ($name, %form);
	
	$name = $elt->att('name');
	
	$form{form} = $elt->atts();

	# flush elements from stash into form hash
	$self->_stash_flush($elt, \%form);
		
	# add form to specification object
	$self->{spec}->form_add(\%form);
}

sub _value_handler {
	my ($self, $elt) = @_;
	my (%value);

	$value{value} = $elt->atts();
	
	$self->{spec}->value_add(\%value);
}

sub _i18n_handler {
	my ($self, $elt) = @_;
	my (%i18n);

	$i18n{value} = $elt->atts();
	
	$self->{spec}->i18n_add(\%i18n);
}

sub _stash_flush {
	my ($self, $elt, $hashref) = @_;

	# examine stash
	for my $item_elt (@{$self->{stash}}) {
		# check whether we are really the parent
		if ($item_elt->parent() eq $elt) {
			push (@{$hashref->{$item_elt->gi()}}, $item_elt->atts());
		}
		else {
			warn "Misplace item in stash (" . $item_elt->gi() . "\n";
		}
	}

	# clear stash
	$self->{stash} = [];

	return;
}

=head2 error

    Returns last error.

=cut

sub error {
	my ($self) = @_;

	if (@{$self->{errors}}) {
		return $self->{errors}->[0]->{error};
	}
}

sub _add_error {
	my ($self, @args) = @_;
	my (%error);

	%error = @args;
	
	unshift (@{$self->{errors}}, \%error);
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
