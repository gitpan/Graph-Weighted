package Graph::Weighted;
use strict;
use Carp;
use vars qw($VERSION); $VERSION = '0.01';
use base qw(Graph);

use constant WEIGHT => 'weight';

sub new {  # {{{
    my ($proto, %args) = @_;
    my $class = ref $proto || $proto;

    my $self = {
        debug      => $args{debug} || 0,
        zero_edges => $args{zero_edges} || 0,
        data       => $args{data} || undef,
    };

    bless $self, $class;

    if ($args{data}) {
        $self->load($args{data});
        $self->graph_weight;
    }

    return $self;
}  # }}}

sub _debug {  # {{{
    print @_, "\n" if shift->{debug};
}  # }}}

sub reset_graph {  # {{{
    my $self = shift;
    undef $self->{data};
    undef $self->{matrix};
    undef $self->{heaviest_vertex};
    undef $self->{lightest_vertex};
    $self->delete_vertices($self->vertices);
    $self->delete_attribute(WEIGHT);
}  # }}}

sub load {  # {{{
    my ($self, $data) = @_;
$self->_debug("entering load with $data");

    if (ref ($data) eq 'HASH') {
        # Set the object matrix to the HoH data.
        $self->{matrix} = $data;

        # Set the vertices and weighted edges.
        while (my ($vertex, $neighbors) = each %$data) {
            unless (keys %$neighbors) {
$self->_debug("$vertex edgeless");
                $self->add_vertex($vertex);
            }

            while (my ($neighbor, $n) = each %$neighbors) {
$self->_debug("$vertex =($n)=> $neighbor");
                $self->add_weighted_edge($vertex, $n, $neighbor)
                    if $self->{zero_edges} || $n != 0;
            }
        }
    }
    # We are given a LoL.
    elsif (ref ($data) eq 'ARRAY') {
        # Set the vertices and weighted edges.
        for my $vertex (0 .. @$data - 1) {
            croak "Incorrectly sized array\n"
                unless @{ $data->[$vertex] } == @$data;

            for my $neighbor (0 .. @{ $data->[$vertex] } - 1) {
                my $n = $data->[$vertex][$neighbor];

$self->_debug("$vertex =($n)=> $neighbor");
                $self->add_weighted_edge($vertex, $n, $neighbor)
                    if $self->{zero_edges} || $n != 0;

                $self->{matrix}{$vertex}{$neighbor} = $n;
            }
        }
    }
    else {
        croak "Unknown data format\n";
    }
$self->_debug('exiting load');
}  # }}}

sub matrix {  # {{{
    return shift->{matrix};
}  # }}}

sub graph_weight {  # {{{
    my $self = shift;
$self->_debug('entering graph_weight');

    unless ($self->has_attribute(WEIGHT)) {
$self->_debug('computing graph_weight');
        my $weight = 0;

        for ($self->vertices) {
            $weight += $self->vertex_weight($_);
$self->_debug("$weight += vertex_weight($_)");
        }

        $self->set_attribute(WEIGHT, $weight);
    }

$self->_debug('exiting graph_weight');
    return $self->get_attribute(WEIGHT);
}  # }}}

sub vertex_weight {  # {{{
    my ($self, $vertex, $weight) = @_;
$self->_debug("entering vertex_weight with $vertex");

    if (defined $weight) {
        # Distribute the weight to all outgoing edges.
$self->_debug("weight is defined as $weight");
        # Out with the old; in with the new.
        my $old = $self->get_attribute(WEIGHT, $vertex);
        $self->set_attribute(WEIGHT, $vertex, $weight);

        # How many neighbors does the vertex have?
        my $n_neighbors = keys %{ $self->{matrix}{$vertex} };

        # Distribute the weight to all outgoing edges.
        my $new_weight = $weight / $n_neighbors;
        for my $neighbor (keys %{ $self->{matrix}{$vertex} }) {
            # Reset the matrix value.
            $self->{matrix}{$vertex}{$neighbor} = $new_weight;
            # Reset the outgoing edge.
            $self->set_attribute(WEIGHT, $vertex, $neighbor, $new_weight);
$self->_debug("$vertex =($new_weight)=> $neighbor: new vertex weight set");
        }

        # Adjust the total graph weight if we made a change.
        if ($old != $weight) {
            my $graph_weight = $self->get_attribute(WEIGHT);

            $graph_weight += $weight - $old;

$self->_debug("adjust the graph weight to $graph_weight");
            $self->set_attribute(WEIGHT, $graph_weight);
        }
    }
    elsif (!$self->has_attribute(WEIGHT, $vertex)) {
        $weight += $_ for values %{ $self->{matrix}{$vertex} };
        $weight = 0 unless $weight;
$self->_debug("weight computed as $weight");
        $self->set_attribute(WEIGHT, $vertex, $weight);
    }

$self->_debug('exiting vertex_weight');
    return $self->get_attribute(WEIGHT, $vertex);
}  # }}}

sub edge_weight {  # {{{
    my ($self, $vertex, $neighbor, $weight) = @_;
$self->_debug("entering edge_weight with $vertex and $neighbor");

    if (defined $weight) {
$self->_debug("weight is defined as $weight");
        # Out with the old; in with the new.
        my $old = $self->get_attribute(WEIGHT, $vertex, $neighbor);

        # Reset the edge weight.
        $self->set_attribute(WEIGHT, $vertex, $neighbor, $weight);

        # Reset the matrix value.
        $self->{matrix}{$vertex}{$neighbor} = $weight;
$self->_debug("$vertex =($weight)=> $neighbor: new vertex weight set");

        # Adjust the graph and vertex weight if we made a change.
        if ($old != $weight) {
            my $graph_weight = $self->get_attribute(WEIGHT);
            $graph_weight += $weight - $old;
$self->_debug("adjust the graph weight to $graph_weight");
            $self->set_attribute(WEIGHT, $graph_weight);

            my $vertex_weight = $self->get_attribute(WEIGHT, $vertex);
            $vertex_weight += $weight - $old;
$self->_debug("adjust the vertex weight to $vertex_weight");
            $self->set_attribute(WEIGHT, $vertex, $vertex_weight);
        }
    }
    elsif (!$self->has_attribute(WEIGHT, $vertex, $neighbor)) {
        $weight = $self->{matrix}{$vertex}{$neighbor};
$self->_debug("weight from the matrix is $weight");
        $self->set_attribute(WEIGHT, $vertex, $neighbor, $weight);
    }

$self->_debug('exiting edge_weight');
    return $self->get_attribute(WEIGHT, $vertex, $neighbor);
}  # }}}

sub heaviest_vertices {  # {{{
    my $self = shift;
$self->_debug('entering heaviest_vertices');

    unless (defined $self->{heaviest_vertices}) {
        my $heavy = 0;

        for ($self->vertices) {
            my $weight = $self->vertex_weight($_);
$self->_debug("vertex_weight($_) = $weight");

            if (!defined $heavy || $weight > $heavy) {
                $heavy = $weight;
                $self->{heaviest_vertices} = [ $_ ];
            }
            elsif ($weight == $heavy) {
                push @{ $self->{heaviest_vertices} }, $_;
            }
        }
    }

$self->_debug('exiting heaviest_vertices with ['. join (', ', @{ $self->{heaviest_vertices} }) . ']');
    return $self->{heaviest_vertices};
}  # }}}

sub lightest_vertices {  # {{{
    my $self = shift;
$self->_debug('entering lightest_vertices');

    unless (defined $self->{lightest_vertices}) {
        my $light;

        for ($self->vertices) {
            my $weight = $self->vertex_weight($_);
$self->_debug("vertex_weight($_) = $weight");

            if (!defined $light || $weight < $light) {
                $light = $weight;
                $self->{lightest_vertices} = [ $_ ];
            }
            elsif ($weight == $light) {
                push @{ $self->{lightest_vertices} }, $_;
            }
        }
    }

$self->_debug('exiting lightest_vertices with ['. join (', ', @{ $self->{lightest_vertices} }) . ']');
    return $self->{lightest_vertices};
}  # }}}

1;

__END__

=head1 NAME

Graph::Weighted - A weighted graph implementation

=head1 SYNOPSIS

  use Graph::Weighted;

  $g = Graph::Weighted->new(
      data => {
          a => { b => 1, c => 2, },  # Nodes with two edges.
          b => { a => 1, c => 3, },
          c => { a => 2, b => 3, },
          d => { c => 1, },          # A vertex with one edge.
          e => {},                   # A vertex with no edges.
     }
  );

  $g->reset_graph;

  $g = Graph::Weighted->new();

  $g->load(
      [ [ 0, 1, 2 ],
        [ 1, 0, 3 ],
        [ 2, 3, 0 ], ]
  );

  $w = $g->graph_weight;

  $heaviest = $g->heaviest_vertices;
  $lightest = $g->lightest_vertices;

  $x = $g->vertex_weight($heaviest->[$i]) if @$heaviest;
  $y = $g->vertex_weight($lightest->[$j]) if @$lightest;

  $x = $g->vertex_weight(0);
  $y = $g->vertex_weight(0, $x + 1);

  $m = $g->matrix;

=head1 ABSTRACT

A weighted graph implementation

=head1 DESCRIPTION

A C<Graph::Weighted> object represents a subclass of C<Graph> with 
weighted attributes that are taken from a 2D matrix (HoH or NxN LoL) 
of numerical values.

Initially, the weights of the vertices are set to the sum of their 
outgoing edge weights.  This is mutable, however, and can be set to 
any value desired, after initialization, with the C<vertex_weight> 
method.

=head1 PUBLIC METHODS

=over 4

=item new HASH

=over 4

=item debug 0 | 1

Flag to invoke verbose mode while processing.  Defaults to zero.

=item zero_edges 0 | 1

Flag to add edges between vertices with a weight of zero.  Defaults to 
zero.

=item data HASHREF | ARRAYREF

Two dimensional hash or (2D, square) array reference to use for 
vertices and weighted edges.

=back

=item reset_graph

Erase the graph's vertices, edges and attributes.

=item load HASHREF | ARRAYREF

Turn the given two dimensional hash or (2D, square) array reference 
into the vertices and weighted edges of a C<Graph> object.

=item matrix

Return the two dimensional hash used for vertices and weighted edges.

=item graph_weight

Get the total weight of the graph, by summing all the vertex weights.

=item vertex_weight SCALAR [, SCALAR]

Return the weight of a vertex.  This method can also be used to set 
the vertex weight, if a second argument is provided.

When the second argument is provided, the weight it represents is 
distributed evenly to the vertex's outgoing edges, and the total 
weight of the entire graph is adjusted accordingly.

=item edge_weight SCALAR, SCALAR [, SCALAR]

Return the weight of an edge.  This method can also be used to set
the edge weight, if a third argument is provided.

When the third argument is provided, the weight it represents is used
to replace the weight of the edge between the vertex (first argument)
and it's neighbor (second argument).  Lastly, the total weight of the 
entire graph and the weight of the vertex are adjusted accordingly.

=item heaviest_vertices

Return the array reference of vertices with the most weight.

=item lightest_vertices

Return the array reference of vertices with the least weight.

=back

=head1 PRIVATE METHODS

=over 4

=item _debug ARRAY

Print the contents of the argument array with a newline appended.

=back

=head1 SEE ALSO

L<Graph>

=head1 TO DO

Handle clusters of vertices and sub-graphs.

=head1 AUTHOR

Gene Boggs E<lt>cpan@ology.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
