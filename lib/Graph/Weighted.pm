package Graph::Weighted;

use warnings;
use strict;

our $VERSION = '0.5';

use base qw(Graph);

use constant DEBUG => 0;
use constant WEIGHT => 'weight';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    bless $self, $class;
    return $self;
}

sub populate {
    my ($self, $data, $method, $attr) = @_;
    warn "populate(): $data\n" if DEBUG;

    # Set the default method.
    $method ||= undef;
    # Set the default attribute.
    $attr ||= WEIGHT;

    my $vertex = 0; # Initial vertex id.

    for my $neighbors (@$data) {
        warn "Neighbors of $vertex: [@$neighbors]\n" if DEBUG;
        $self->_add_weighted_edges($vertex, $neighbors, $method, $attr);
        $vertex++; # Move on to the next vertex...
    }
}

sub _add_weighted_edges {
    my ($self, $vertex, $neighbors, $method, $attr) = @_;
    warn "add_weighted_edges(): $vertex, $neighbors, $attr\n" if DEBUG;

    # Initial vertex weight
    my $weight = 0;

    # Make nodes and edges.
    for my $n (0 .. @$neighbors - 1) {
        next unless $neighbors->[$n]; # Skip zero weight nodes.
        warn "Edge: $vertex <-> $n\n" if DEBUG;
        # Add a node-node edge to the graph.
        $self->add_edge($vertex, $n);
        # Do the heavy lilfting:
        $weight = _compute_weight($neighbors->[$n], $weight, $method, $attr);
    }

    # Set the weight of the graph node.
    warn "$vertex weight = $weight\n" if DEBUG;
    # TODO Handle multi-attribute update (not just weight).
    $self->set_vertex_attribute($vertex, $attr, $weight);
}

sub _compute_weight {
    my ($node_weight, $current, $method, $attr) = @_;
    warn "compute_weight(): $node_weight, $current\n" if DEBUG;
    # Call the weight function if one is given.
    return $method->($node_weight, $current, $attr) if $method and ref $method eq 'CODE';
    # Increment the current value by the node weight if no weight function is given.
    return $node_weight + $current;
}

sub get_weight {
    my $self = shift;
    warn "get_weight(@_)\n" if DEBUG;
    return $self->get_attr(@_);
}
sub get_attr {
    my ($self, $vertex, $attr) = @_;
    die 'ERROR: No vertex given to get_attr()' unless defined $vertex;
    $attr ||= WEIGHT;
warn"get_attr() $vertex, $attr\n" if DEBUG;
    return $self->get_vertex_attribute($vertex, $attr);
}

1;
__END__

=head1 NAME

Graph::Weighted - A weighted graph implementation

=head1 SYNOPSIS

  use Graph::Weighted;
  my $g = Graph::Weighted->new();
  $g->populate(
      [
        [ 0, 1, 2, 0, 0 ],  # A vertex of weight 3 with two edges.
        [ 1, 0, 3, 0, 0 ],  # A vertex of weight 4 with two edges.
        [ 2, 3, 0, 0, 0 ],  # A vertex of weight 5 with two edges.
        [ 0, 0, 1, 0, 0 ],  # A vertex of weight 1 with one edge.
        [ 0, 0, 0, 0, 0 ]   # A vertex of weight 0 with no edges.
      ]
  );
  my $weight = $g->get_weight($vertex);
  my $magnitude = $g->get_attr($vertex, 'magnitude');

=head1 DESCRIPTION

A C<Graph::Weighted> object is a subclass of C<Graph> with weighted
attributes.

This module is a streamlined version of the weight based accessors
provided by the C<Graph> module.

=head1 METHODS

=head2 new(%arguments)

Return a new C<Graph::Weighted> object.

See L<Graph> for the possible constructor arguments.

=head2 populate($data, $method, $attribute)

  data      => 2D ARRAYREF of numbers
  method    => Optional CODEREF weighting function
  attribute => Optional STRING

Populate the graph with weighted nodes (attribute named 'weight' by
default).

The default weighting function is a simple sum of the neighbor weight
values.  An alternative may be provided, which should accept arguments
of the current node weight, current weight total and the attribute to
update.  For example:

  sub weight_function {
    my ($current_node_weight, $current_weight_total, attribute);
    return $current_weight_total / $current_node_weight;
  }

=head2 get_weight($vertex) and get_attr($vertex, $attribute);

Return the attribute value.

=head1 TO DO

Accept hashrefs and C<Matrix::*> objects instead of just LoLs.

Make subroutines for finding the heaviest and lightest nodes.

Make subroutines for finding the total weight beneath a node.

=head1 SEE ALSO

L<Graph>

The F<t/*> sources.

=head1 TO DO

Handle hashref data.

Handle Matrix::* objects as data.

=head1 AUTHOR

Gene Boggs, C<< <gene at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2003-2012 Gene Boggs.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

=cut
