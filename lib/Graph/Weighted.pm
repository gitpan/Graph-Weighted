package Graph::Weighted;
# ABSTRACT: A weighted graph implementation

use warnings;
use strict;

our $VERSION = '0.52';

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
    my ($self, $data, $attr, $method) = @_;
    warn "populate(): $data\n" if DEBUG;

    # Set the default attribute.
    $attr ||= WEIGHT;
    # Set the default method.
    $method ||= undef;

    # What type of data are we given?
    my $data_ref = ref $data;

    if ($data_ref eq 'ARRAY') {
        my $vertex = 0; # Initial vertex id.
        for my $neighbors (@$data) {
            warn "Neighbors of $vertex: [@$neighbors]\n" if DEBUG;
            $self->_add_weighted_edges_from_array($vertex, $neighbors, $attr, $method);
            $vertex++; # Move on to the next vertex...
        }
    }
    elsif ($data_ref eq 'HASH') {
        for my $vertex (keys %$data) {
            warn "Neighbors of $vertex: [", join(' ', values %{$data->{$vertex}}), "]\n" if DEBUG;
            $self->_add_weighted_edges_from_hash($vertex, $data->{$vertex}, $attr, $method);
        }
    }
    else {
        warn "Unknown data type: $data\n";
    }
}

sub _add_weighted_edges_from_array {
    my ($self, $vertex, $neighbors, $attr, $method) = @_;
    warn "add_weighted_edges(): $vertex, $neighbors, $attr\n" if DEBUG;
    # Initial vertex weight
    my $vertex_weight = 0;
    # Make nodes and edges.
    for my $n (0 .. @$neighbors - 1) {
        my $w = $neighbors->[$n]; # Weight of the edge to the neighbor.
        next unless $w; # TODO Skip zero weight nodes if requested?
        # Add a node-node edge to the graph.
        $self->add_edge($vertex, $n);
        # Set the weight of the edge.
        my $edge_weight = _compute_edge_weight($w, $attr, $method);
        warn "Edge: $vertex -($edge_weight)-> $n\n" if DEBUG;
        $self->set_edge_attribute($vertex, $n, $attr, $edge_weight);
        # Tally the weight of the vertex.
        $vertex_weight = _compute_vertex_weight($w, $vertex_weight, $attr, $method);
    }
    # Set the weight of the graph node.
    warn "Vertex $vertex $attr = $vertex_weight\n" if DEBUG;
    $self->set_vertex_attribute($vertex, $attr, $vertex_weight);
}

sub _add_weighted_edges_from_hash {
    my ($self, $vertex, $neighbors, $attr, $method) = @_;
    warn "add_weighted_edges(): $vertex, $neighbors, $attr\n" if DEBUG;
    # Initial vertex weight
    my $vertex_weight = 0;
    # Make nodes and edges.
    for my $n (keys %$neighbors) {
        my $w = $neighbors->{$n}; # Weight of the edge to the neighbor.
        # Add a node-node edge to the graph.
        $self->add_edge($vertex, $n);
        # Set the weight of the edge.
        my $edge_weight = _compute_edge_weight($w, $attr, $method);
        warn "Edge: $vertex -($edge_weight)-> $n\n" if DEBUG;
        $self->set_edge_attribute($vertex, $n, $attr, $edge_weight);
        # Tally the weight of the vertex.
        $vertex_weight = _compute_vertex_weight($w, $vertex_weight, $attr, $method);
    }
    # Set the weight of the graph node.
    warn "Vertex $vertex $attr = $vertex_weight\n" if DEBUG;
    $self->set_vertex_attribute($vertex, $attr, $vertex_weight);
}

sub _compute_edge_weight {
    my ($weight, $attr, $method) = @_;
    warn "compute_edge_weight(): $attr $weight\n" if DEBUG;
    # Call the weight function if one is given.
    return $method->($weight, $attr) if $method and ref $method eq 'CODE';
    # Increment the current value by the node weight if no weight function is given.
    return $weight;
}

sub _compute_vertex_weight {
    my ($weight, $current, $attr, $method) = @_;
    warn "compute_vertex_weight(): $attr $weight, $current\n" if DEBUG;
    # Call the weight function if one is given.
    return $method->($weight, $current, $attr) if $method and ref $method eq 'CODE';
    # Increment the current value by the node weight if no weight function is given.
    return $weight + $current;
}

sub get_weight {
    my $self = shift;
    return $self->get_attr(@_);
}
sub get_attr {
    my ($self, $v, $attr) = @_;
    die 'ERROR: No vertex given to get_attr()' unless defined $v;
    $attr ||= WEIGHT;
    warn"get_attr($v, $attr)\n" if DEBUG;
    if (ref $v eq 'ARRAY') {
        return $self->get_edge_attribute(@$v, $attr);
    }
    else {
        return $self->get_vertex_attribute($v, $attr);
    }
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
        [ 0, 1, 2, 0, 0 ], # Vertex with 5 edges of weight 3
        [ 1, 0, 3, 0, 0 ], #               "               4
        [ 2, 3, 0, 0, 0 ], #               "               5
        [ 0, 0, 1, 0, 0 ], #               "               1
        [ 0, 0, 0, 0, 0 ], #               "               0
    ]
  );
  $g->populate(
    {
        0 => { 1=>2, 2=>1 },             # Vertex with 2 edges of weight 3
        1 => { 0=>3, 2=>1 },             #      "      2        "        4
        2 => { 0=>3, 1=>2 },             #      "      2        "        5
        3 => { 1=>2 },                   #      "      1        "        2
        4 => { 0=>1, 1=>1, 2=>1, 3=>1 }, #      "      4        "        4
    },
    'magnitude'
  );
  for my $v ($g->vertices) {
    my $w = $g->get_weight($v) || 0;
    warn "V: $v = $w\n";
  }
  for my $e ($g->edges) {
    my $w = $g->get_weight($e) || 0;
    my $m = $g->get_attr($e, 'magnitude') || 0;
    warn "E: @$e = $w $m\n";
  }

=head1 DESCRIPTION

A C<Graph::Weighted> object is a subclass of C<Graph> with weighted
attributes.  As such, all of the C<Graph> methods may be used as
documented.  This module is a streamlined, simplified version of the
weight based accessors provided by the C<Graph> module.

=head1 METHODS

=head2 new(%arguments)

Return a new C<Graph::Weighted> object.

See L<Graph> for the possible constructor arguments.

=head2 populate($data, $attribute, $method)

  $g->populate(\@vectors)
  $g->populate(
    { a => { b=>2, c=>1 },
      b => { a=>3, c=>1 },
      c => { a=>3, b=>2 },
      d => { b=>2 },
      e => { a=>1, b=>1, c=>1, d=>1 },
    },
  );

Arguments:

  data      => Array ref of numeric vectors or HASH ref of numeric edge values
  attribute => Optional string name
  method    => Optional code ref weighting function

Populate a graph with weighted nodes.

Example of array reference nodes:

  []      no edges
  [0]     1 vertex and 1 edge to node 0 (weight 0)
  [1]     1 vertex and 1 edge to node 0 (vertex & edge weights 1)
  [0,1]   2 vertices and 2 edges (edge weights 0,1; vertex weight 1)
  [0,1,9] 3 vertices and 3 edges (edge weights 0,1,9; vertex weight 10)

The default edge weighting function returns the value in the neighbor
position.  An alternative may be provided, as a subroutine reference,
which should accept the current edge weight and the attribute to update.
For example:

  sub edge_weight_function {
    my ($weight, attribute);
    return $current_weight_total / $current_node_weight;
  }

The default vertex weighting function is a simple sum of the neighbor
weight values.  An alternative may be provided, which should accept
of the current node weight, current weight total and the
attribute as arguments to update.  For example:

  sub vertex_weight_function {
    my ($current_node_weight, $current_weight_total, attribute);
    return $current_weight_total / $current_node_weight;
  }

The attribute is named 'weight' by default but may be anything of
your choosing.  This method can be called multiple times on the same
graph, for nodes of different attributes.

=head2 get_weight($vertex), get_weight($edge), get_attr($vertex, $attribute), get_attr($edge, $attribute)

  $g->get_weight($vertex);
  $g->get_attr($vertex, $attribute);
  $g->get_weight($edge);
  $g->get_attr($edge, $attribute);

Return the attribute value for the vertex or edge.  A vertex is a
numeric value.  An edge is an array reference with 2 elements.

=head1 TO DO

Accept hashrefs and C<Matrix::*> objects instead of just LoLs.

Make subroutines for finding the heaviest and lightest nodes.

Make subroutines for finding the total weight beneath a node.

=head1 SEE ALSO

L<Graph>

The F<t/*> sources.

=head1 AUTHOR

Gene Boggs, C<< <gene at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2003-2012 Gene Boggs.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

=cut
