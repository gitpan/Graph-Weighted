package Graph::Weighted::Capacity;
use strict;
use Carp;
use vars qw($VERSION); $VERSION = '0.01';
use base qw(Graph::Weighted);

use constant CAPACITY => 'capacity';

sub new {
    my ($proto, %args) = @_;
    my $class = ref $proto || $proto;
    my $self = Graph::Weighted->new(
        default_attribute => CAPACITY,
        %args,
    );
    bless $self, $class;
    return $self;
}

sub load_capacity  { shift->load(@_, CAPACITY) }

sub capacity_data  { shift->data(@_, CAPACITY) }

sub graph_capacity { shift->graph_attr(@_, CAPACITY) }

sub max_capacity   { shift->max_attr(CAPACITY) }

sub min_capacity   { shift->min_attr(CAPACITY) }

sub vertex_capacity {
    my $self = shift;
    $self->vertex_attr(
        vertex => shift,
        value  => shift,
        attr   => CAPACITY,
    );
}

sub edge_capacity {
    my $self = shift;
    $self->edge_attr(
        vertex    => shift,
        successor => shift,
        value     => shift,
        attr      => CAPACITY,
    );
}

1;

__END__

=head1 NAME

Graph::Weighted::Capacity - A capacity graph implementation

=head1 SYNOPSIS

  use Graph::Weighted::Capacity;

  $g = Graph::Weighted::Capacity->new(
      data => [
          [ 0, 1, 2, 0, 0 ],  # A vertex with two edges.
          [ 1, 0, 3, 0, 0 ],  # "
          [ 2, 3, 0, 0, 0 ],  # "
          [ 0, 0, 1, 0, 0 ],  # A vertex with one edge.
          [ 0, 0, 0, 0, 0 ]   # A vertex with no edges.
      ]
  );

  $g = Graph::Weighted::Capacity->new(
      data => {
          capacity => {
              a => { b => 1, c => 2 },  # A vertex with two edges.
              b => { a => 1, c => 3 },  # "
              c => { a => 2, b => 3 },  # "
              d => { c => 1 },          # A vertex with one edge.
              e => {}                   # A vertex with no edges.
          },
          weight => [
              [ 1, 2, 3, 4, 5 ],
              [ 6, 7, 8, 9, 0 ],
              [ 1, 2, 3, 4, 5 ],
              [ 6, 7, 8, 9, 0 ],
              [ 0, 1, 0, 1, 0 ]
          ],
      }
  );

  $g = Graph::Weighted::Capacity->new(
      data => $Math_Matrix_object
  );

  $data = $g->capacity_data;

  $c = $g->graph_capacity;

  $c = $g->vertex_capacity($v1);
  $c = $g->vertex_capacity($v1, $c + 1);

  $c = $g->edge_capacity($v1, $v2);
  $c = $g->edge_capacity($v1, $v2, $c + 1);

  $vertices = $g->largest_vertices;
  $vertices = $g->smallest_vertices;

  $c = $g->max_capacity;  # Capacity of the largest vertices.
  $c = $g->min_capacity;  # Capacity of the smallest vertices.

  # Call the capacity methods of the inherited Graph module.
  $x = $g->Flow_Ford_Fulkerson($state);
  $x = $g->Flow_Edmonds_Karp($source, $sink);

=head1 DESCRIPTION

A C<Graph::Weighted::Capacity> object represents a subclass of 
C<Graph::Weighted> with capacity attributes that are taken from a two 
dimensional matrix of numerical values.

This module can also load the matrix portions of C<Math::Matrix>, 
C<Math::MatrixReal>, and C<Math::MatrixBool> objects.

Initially, the capacities of the vertices are set to the sum of their 
outgoing edge capacities.  This is mutable, however, and can be reset 
to any value desired, after initialization, with the 
C<vertex_capacity> and C<edge_capacity> methods.

=head1 PUBLIC METHODS

=over 4

=item * new %ARGUMENTS

=over 4

=item debug => 0 | 1

Flag to invoke verbose mode while processing.  Defaults to zero.

=item zero_edges => 0 | 1

Flag to add edges between vertices with a capacity of zero.  Defaults 
to zero.

=item data => $HASHREF | $ARRAYREF | $OBJECT

Two dimensional hash (HoH), (NxN) array, or object reference to use 
for vertex and edge capacities.

C<Math::Matrix>, C<Math::MatrixReal>, and C<Math::MatrixBool> objects 
can also be loaded.

=back

=item * load_capacity $HASHREF | $ARRAYREF | $OBJECT

Turn the given two dimensional hash, (NxN) array, or object reference 
into the vertices and edges of a C<Graph::Directed> object.

C<Math::Matrix>, C<Math::MatrixReal>, and C<Math::MatrixBool> objects 
can also be loaded.

=item * capacity_data

Return a two dimensional hash of vertices and thier edge capacities.

=item * graph_capacity

Get the total capacity of the graph, which is the sum of all the 
vertex capacities.

=item * vertex_capacity $VERTEX [, $CAPACITY]

Return the capacity of a vertex.

(The vertices are just the keys of the data, not some glorified 
object, by the way.)

If a second argument is provided, the vertex capacity is set to that 
value and is distributed evenly to the vertex's outgoing edges, and 
the total capacity of the graph is adjusted accordingly.

=item * edge_capacity $VERTEX, $SUCCESSOR [, $CAPACITY]

Return the capacity of an edge between the two given vertices.

If a third argument is provided, the capacity it represents is used
to replace the capacity of the edge between the vertex (first argument)
and it's successor (second argument).  Finally, the capacity of the 
vertex and the total capacity of the graph are adjusted accordingly.

=item * largest_vertices

Return an array reference of vertices with the most capacity.

=item * smallest_vertices

Return an array reference of vertices with the least capacity.

=item * max_capacity

Return the capacity of the largest vertices.

=item * min_capacity

Return the capacity of the smallest vertices.

=back

=head1 PRIVATE METHODS

=over 4

=item * _debug @STUFF

Print the contents of the argument array with a newline appended.

=back

=head1 SEE ALSO

L<Graph::Base>

L<Graph::Weighted>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
