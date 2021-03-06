package Template::Flute::Specification;

use strict;
use warnings;

use Template::Flute::Iterator;

=head1 NAME

Template::Flute::Specification - Specification class for Template::Flute

=head1 SYNOPSIS

    $xml_spec = new Template::Flute::Specification::XML;
    $spec = $xml_spec->parse_file('spec.xml');
    $spec->set_iterator('cart', $cart);

    $conf_spec = new Template::Flute::Specification::Scoped;
    $spec = $conf_spec->parse_file('spec.conf);

=head1 DESCRIPTION

Specification class for L<Template::Flute>.

=head1 CONSTRUCTOR

=head2 new

Creates Template::Flute::Specification object.

=cut

# Constructor

sub new {
	my ($class, $self);
	my (%params);

	$class = shift;
	%params = @_;

	$self = \%params;

	# lookup hash for elements by class
	$self->{classes} = {};

	# lookup hash for elements by id
	$self->{ids} = {};
	
	bless $self;
}

=head1 METHODS

=head2 container_add CONTAINER

Add container specified by hash reference CONTAINER.

=cut

sub container_add {
	my ($self, $new_containerref) = @_;
	my ($containerref, $container_name, $class);

	$container_name = $new_containerref->{container}->{name};

	$containerref = $self->{containers}->{$new_containerref->{container}->{name}} = {input => {}};

	$class = $new_containerref->{container}->{class} || $container_name;

	$self->{classes}->{$class} = {%{$new_containerref->{container}}, type => 'container'};

	return $containerref;
}

=head2 list_add LIST

Add list specified by hash reference LIST.

=cut
	
sub list_add {
	my ($self, $new_listref) = @_;
	my ($listref, $list_name, $class);

	$list_name = $new_listref->{list}->{name};

	$listref = $self->{lists}->{$new_listref->{list}->{name}} = {input => {}};

	$class = $new_listref->{list}->{class} || $list_name;

	$self->{classes}->{$class} = {%{$new_listref->{list}}, type => 'list'};

	if (exists $new_listref->{list}->{iterator}) {
		$listref->{iterator} = $new_listref->{list}->{iterator};
	}

	# loop through filters for this list
	for my $filter (@{$new_listref->{filter}}) {
		$listref->{filter}->{$filter->{name}} = $filter;
	}

	# loop through inputs for this list
	for my $input (@{$new_listref->{input}}) {
		$listref->{input}->{$input->{name}} = $input;
	}

	# loop through sorts for this list
	for my $sort (@{$new_listref->{sort}}) {
		$listref->{sort}->{$sort->{name}} = $sort;
	}
	
	# loop through params for this list
	for my $param (@{$new_listref->{param}}) {
		$class = $param->{class} || $param->{name};
		$self->{classes}->{$class} = {%{$param}, type => 'param', list => $list_name};	
	}

	# loop through paging for this list
	for my $paging (@{$new_listref->{paging}}) {
		if (exists $listref->{paging}) {
			die "Only one paging allowed per list\n";
		}
		$listref->{paging} = $paging;
		$class = $paging->{class} || $paging->{name};
		$self->{classes}->{$class} = {%{$paging}, type => 'paging', list => $list_name};	
	}
	
	return $listref;
}

=head2 form_add FORM

Add form specified by hash reference FORM.

=cut
	
sub form_add {
	my ($self, $new_formref) = @_;
	my ($formref, $form_name, $id, $class);

	$form_name = $new_formref->{form}->{name};

	$formref = $self->{forms}->{$new_formref->{form}->{name}} = {input => {}};

	if ($id = $new_formref->{form}->{id}) {
		$self->{ids}->{$id} = {%{$new_formref->{form}}, type => 'form'};
	}
	else {
		$class = $new_formref->{form}->{class} || $form_name;

		$self->{classes}->{$class} = {%{$new_formref->{form}}, type => 'form'};
	}
	
	# loop through inputs for this form
	for my $input (@{$new_formref->{input}}) {
		$formref->{input}->{$input->{name}} = $input;
	}
	
	# loop through params for this form
	for my $param (@{$new_formref->{param}}) {
		$class = $param->{class} || $param->{name};

		$self->{classes}->{$class} = {%{$param}, type => 'param', form => $form_name};	
	}

	# loop through fields for this form
	for my $field (@{$new_formref->{field}}) {
		if (exists $field->{id}) {
			$self->{ids}->{$field->{id}} = {%{$field}, type => 'field', form => $form_name};
		}
		else {
			$class = $field->{class} || $field->{name};
			$self->{classes}->{$class} = {%{$field}, type => 'field', form => $form_name};
		}
	}
	
	return $formref;
}

=head2 value_add VALUE

Add value specified by hash reference VALUE.

=cut
	
sub value_add {
	my ($self, $new_valueref) = @_;
	my ($valueref, $value_name, $id, $class);
	
	$value_name = $new_valueref->{value}->{name};

	$valueref = $self->{values}->{$new_valueref->{value}->{name}} = {};
	
	if ($id = $new_valueref->{value}->{id}) {
		$self->{ids}->{$id} = {%{$new_valueref->{value}}, type => 'value'};
	}
	else {
		$class = $new_valueref->{value}->{class} || $value_name;

		$self->{classes}->{$class} = {%{$new_valueref->{value}}, type => 'value'};
	}

	return $valueref;
}	

=head2 i18n_add I18N

Add i18n specified by hash reference I18N.

=cut
	
sub i18n_add {
	my ($self, $new_i18nref) = @_;
	my ($i18nref, $i18n_name, $id, $class);

	$i18n_name = $new_i18nref->{value}->{name};
	
	$i18nref = $self->{i18n}->{$new_i18nref->{value}->{name}} = {};
	
	if ($id = $new_i18nref->{value}->{id}) {
		$self->{ids}->{$id} = {%{$new_i18nref->{value}}, type => 'i18n'};
	}
	else {
		$class = $new_i18nref->{value}->{class} || $i18n_name;

		$self->{classes}->{$class} = {%{$new_i18nref->{value}}, type => 'i18n'};
	}
	
	return $i18nref;
}

=head2 list_iterator NAME

Returns iterator for list named NAME or undef.

=cut

sub list_iterator {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{iterator};
	}
}

=head2 list_inputs NAME

Returns inputs for list named NAME or undef.

=cut
	
sub list_inputs {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{input};
	}
}

=head2 list_sorts NAME

Return sorts for list named NAME or undef.

=cut

sub list_sorts {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{sort};
	}
}

=head2 list_filters NAME

Return filters for list named NAME or undef.

=cut

sub list_filters {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{filter};
	}
}

=head2 form_inputs NAME

Return inputs for form named NAME or undef.

=cut

sub form_inputs {
	my ($self, $form_name) = @_;

	if (exists $self->{forms}->{$form_name}) {
		return $self->{forms}->{$form_name}->{input};
	}
}

=head2 iterator NAME

Returns iterator identified by NAME.

=cut

sub iterator {
	my ($self, $name) = @_;

	if (exists $self->{iters}->{$name}) {
		return $self->{iters}->{$name};
	}
}

=head2 set_iterator NAME ITER

Sets iterator for NAME to ITER. ITER can be a iterator
object like L<Template::Flute::Iterator> or a reference
to an array containing hash references.

=cut

sub set_iterator {
	my ($self, $name, $iter) = @_;
	my ($iter_ref);

	$iter_ref = ref($iter);

	if ($iter_ref eq 'ARRAY') {
		$iter = new Template::Flute::Iterator($iter);
	}
	
	$self->{iters}->{$name} = $iter;
}

=head2 resolve_iterator INPUT

Resolves iterator INPUT.

=cut

sub resolve_iterator {
	my ($self, $input) = @_;
	my ($input_ref, $iter);

	$input_ref = ref($input);

	if ($input_ref eq 'ARRAY') {
		$iter = new Template::Flute::Iterator($input);
	}
	elsif ($input_ref) {
		# iterator already resolved
		$iter = $input_ref;
	}
	elsif (exists $self->{iters}->{$input}) {
		$iter = $self->{iters}->{$input};
	}
	else {
		die "Failed to resolve iterator $input.";
	}

	return $iter;
}

=head2 element_by_class NAME

Returns element of the specification tied to HTML class NAME or undef.

=cut

sub element_by_class {
	my ($self, $class) = @_;

	if (exists $self->{classes}->{$class}) {
		return $self->{classes}->{$class};
	}

	return;
}

=head2 element_by_id NAME

Returns element of the specification tied to HTML id NAME or undef.

=cut

sub element_by_id {
	my ($self, $id) = @_;

	if (exists $self->{ids}->{$id}) {
		return $self->{ids}->{$id};
	}

	return;
}

=head2 list_paging NAME

Returns paging for list NAME.

=cut
	
sub list_paging {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{paging};
	}	
}

=head1 AUTHOR

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-flute at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Flute>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
	
1;
