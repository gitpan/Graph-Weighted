package Graph::Weighted;
use strict;
use Carp;
use vars qw($VERSION); $VERSION = '0.11';
use base qw(Graph::Directed);

use constant WEIGHT => 'weight';

sub _debug {  # {{{
    print @_, "\n" if shift->{debug};
}  # }}}

sub new {  # {{{
    my ($proto, %args) = @_;
    my $class = ref $proto || $proto;

    my $self = {
        debug => $args{debug} || 0,
        zero_edges => $args{zero_edges} || 0,
        attr => $args{default_attribute} || WEIGHT,
        retrieve_as => $args{retrieve_as} || 'HASH',
    };

    bless $self, $class;

    # We need to show the zero edges if we want to retrieve data as
    # an LoL.
    $self->{zero_edges} = 1 if $self->{retrieve_as} eq 'ARRAY';

    $self->_init($args{data}) if $args{data};

    return $self;
}  # }}}

sub _init {  # {{{
    my ($self, $data) = @_;

    if (ref ($data) eq 'HASH') {
        while (my ($attr, $datum) = each %$data) {
            $self->load($datum, $attr);
        }
    }
    elsif (ref ($data) eq 'ARRAY') {
        $self->load($data, $self->{attr});
    }
}  # }}}

sub load_weight { shift->load(@_, WEIGHT) }
sub load {  # {{{
    my ($self, $data, $attr) = @_;

    # Default the attribute, if not given.
    $attr ||= $self->{attr};

$self->_debug("entering load as '$attr' with an ". ref ($data) . ' object');
    croak 'No attribute provided.' unless defined $attr;

    # Math::Matrix* to ARRAY.  {{{
    if (ref ($data) eq 'Math::MatrixReal' ||
        ref ($data) eq 'Math::Matrix'
    ) {
        # Math::Matrix* objects are LoLs and have the matrix as the
        # first element.
        $data = $data->[0];
    }
    elsif (ref ($data) eq 'Math::MatrixBool') {
        # Math::MatrixBool objects are actually Bit::Vectors, 
        # "stringified", like this:
        # [ 1 0 0 ]\n[ 1 1 0 ]\n[ 1 1 1 ]
        # So de-stringification gymnastics happen, in order to get
        # data as an LoL.
        $data = [
            map { [ split ] }
                sprintf ('%s', "$data") =~ /\[\s([\d\s]+)\s\]/gs
        ];
    }  # }}}

    # Initialize the total value.
    my $graph_value = 0;

    if (ref ($data) eq 'HASH') {  # {{{
        # Set the vertices and valued edges.
        while (my ($vertex, $successors) = each %$data) {
            # Add the vertex to the graph, unless it's already there.
            $self->add_vertex($vertex)
                unless $self->has_vertex($vertex);

            # Initialize the vertex attribute value.
            my $value = 0;

            # Add edges with attributes for each successor.
            while (my ($successor, $n) = each %$successors) {
$self->_debug("$vertex =($n)=> $successor");
                # Add the successor to the graph, unless it's already
                # there.
                $self->add_vertex($successor)
                    unless $self->has_vertex($successor);

                # Either we have a successor value or we want to see
                # zero-edges.
                if ($n || $self->{zero_edges}) {
                    # Default the edge value to zero.
                    $n ||= 0;
                    # Tally the vertex value.
                    $value += $n;
                    # Add the edge to the graph, unless it's already
                    # there.
                    $self->add_edge($vertex, $successor)
                        unless $self->has_edge($vertex, $successor);
                    # Set the edge attribute.
                    $self->set_attribute($attr, $vertex, $successor, $n);
                }
            }

            # Set the vertex attribute value.
$self->_debug("$vertex $attr = $value");
            $self->set_attribute($attr, $vertex, $value);

            # Tally the total value.
            $graph_value += $value;
        }
    }  # }}}
    elsif (ref ($data) eq 'ARRAY') {  # {{{
        # Set the vertices and valued edges.
        for my $vertex (0 .. @$data - 1) {
            croak "Incorrectly sized array\n"
                unless @{ $data->[$vertex] } == @$data;

            # Add the vertex to the graph, unless it's already there.
            $self->add_vertex($vertex)
                unless $self->has_vertex($vertex);

            # Initialize the vertex attribute value.
            my $value = 0;

            # Add edges for all the successors.
            for my $successor (0 .. @{ $data->[$vertex] } - 1) {
                # Add the successor to the graph, unless it's already
                # there.
                $self->add_vertex($successor)
                    unless $self->has_vertex($successor);

                # Set the attribute value of the edge.
                my $n = $data->[$vertex][$successor];
                # Default to zero if undef.
                $n ||= 0;

                if ($n || $self->{zero_edges}) {
$self->_debug("$vertex =($n)=> $successor");
                    # Tally the vertex value.
                    $value += $n;
                    # Add the edge to the graph, unless it's already
                    # there.
                    $self->add_edge($vertex, $successor)
                        unless $self->has_edge($vertex, $successor);
                    # Set the edge attribute.
                    $self->set_attribute($attr, $vertex, $successor, $n);
                }
            }

            # Set the vertex.
$self->_debug("$vertex $attr = $value");
            $self->set_attribute($attr, $vertex, $value);

            # Tally the total value.
            $graph_value += $value;
        }
    }  # }}}
    else {
        croak "Unknown data format\n";
    }

    # Set the total value of the graph.
$self->_debug("set the graph $attr to $graph_value");
    $self->set_attribute($attr, $graph_value);
$self->_debug('exiting load');
}  # }}}

sub weight_data { shift->data(@_, WEIGHT) }
sub data {  # {{{
    my ($self, $attr) = @_;
    # Default the attribute, if not given.
    $attr ||= $self->{attr};
$self->_debug("entering data for $attr");

    # The hash or array reference to return.
    my $data;

    # Initialize the i,j counters for array format.
    my ($i, $j) = (0, 0);

    # Build a hash or array ref from the vertices and edge values.
    for my $v ($self->vertices) {
$self->_debug("$i th vertex $v:");

        # Set the vertex.
        if ($self->{retrieve_as} eq 'ARRAY') {
            $data->[$i] = [];
        }
        elsif ($self->{retrieve_as} eq 'HASH') {
            $data->{$v} = {};
        }

        # Add the edge values.
        for ($self->successors($v)) {
            my $n = $self->edge_attr(
                vertex => $v,
                successor => $_,
                attr => $attr,
            );

$self->_debug("$j th successor $_ has $attr of $n");

            if ($self->{retrieve_as} eq 'ARRAY') {
#                $data->[$i][$j] = $n;
                push @{ $data->[$i] }, $n;
            }
            elsif ($self->{retrieve_as} eq 'HASH') {
                $data->{$v}{$_} = $n;
            }

            $j++;
        }

        $i++;
    }

$self->_debug("exiting data");
    return $data;
}  # }}}

sub graph_weight { shift->graph_attr(@_, WEIGHT) }
sub graph_attr {  # {{{
    my ($self, $attr) = @_;

    # Default the attribute, if not given.
    $attr ||= $self->{attr};

$self->_debug("entering graph_attr with $attr");
    croak 'No attribute provided.' unless defined $attr;

    unless ($self->has_attribute($attr)) {
$self->_debug("computing graph $attr");
        my $value = 0;

        for ($self->vertices) {
            $value += $self->vertex_attr(
                vertex => $_,
                attr => $attr,
            );
$self->_debug("$value += vertex_attr($_, $attr)");
        }

        $self->set_attribute($attr, $value);
    }

$self->_debug('exiting graph_attr');
    return $self->get_attribute($attr);
}  # }}}

sub vertex_weight {
    my $self = shift;
    $self->vertex_attr(
        vertex => shift,
        value  => shift,
        attr   => WEIGHT,
    );
}
sub vertex_attr {  # {{{
    my ($self, %args) = @_;

    # Make sure we are given the Right Stuff[tm].
    my $vertex = $args{vertex};
    croak "Can't compute with an undefined vertex."
        unless defined $vertex;
    my $attr = $args{attr} || $self->{attr} ||
        croak 'No attribute provided.';
    my $value = $args{value};

$self->_debug("entering vertex_attr for $attr with vertex $vertex");

    if (defined $value) {
        # Distribute the value to all outgoing edges.
        # Out with the old; in with the new.
        my $old_value = $self->get_attribute($attr, $vertex);
$self->_debug("new $attr defined as $value, old as $old_value");
        $self->set_attribute($attr, $vertex, $value);

        # How many successors does the vertex have?
        my $n_successors = $self->successors($vertex);
$self->_debug("vertex has $n_successors successors");

        # Distribute the value to all outgoing edges.
        my $average_value = $value / $n_successors;
        # Reset the outgoing edges.
        for my $successor ($self->successors($vertex)) {
            $self->set_attribute($attr, $vertex, $successor, $average_value);
$self->_debug("$vertex =($average_value)=> $successor: new outgoing edge $attr set");
        }

        # Adjust the total graph value if we made a change.
        if ($old_value != $value) {
            my $graph_value = $self->get_attribute($attr);
            $graph_value += $value - $old_value;
$self->_debug("adjust the graph $attr to $graph_value");
            $self->set_attribute($attr, $graph_value);
        }
    }
    # The vertex does not possess the sacred attribute.
    elsif (!$self->has_attribute($attr, $vertex)) {
        # Compute the value of the attribute.
        $value += $self->get_attribute($_, $attr)
            for $self->successors($vertex);
        $value = 0 unless $value;
$self->_debug("$attr computed as $value");
        $self->set_attribute($attr, $vertex, $value);
    }

$self->_debug('exiting vertex_attr');
    return $self->get_attribute($attr, $vertex);
}  # }}}

sub edge_weight {
    my $self = shift;
    $self->edge_attr(
        vertex    => shift,
        successor => shift,
        value     => shift,
        attr      => WEIGHT,
    );
}
sub edge_attr {  # {{{
    my ($self, %args) = @_;

    # Make sure we are given the Right Stuff[tm].
    my $vertex = $args{vertex};
    croak "Can't compute with an undefined vertex."
        unless defined $vertex;
    my $successor = $args{successor};
    croak "Can't compute with an undefined successor."
        unless defined $successor;;
    my $attr = $args{attr} || $self->{attr} ||
        croak 'No attribute provided.';
    my $value = $args{value};

$self->_debug("entering edge_attr for $attr with vertex $vertex and successor $successor");

    if (defined $value) {
$self->_debug("$attr is defined as $value");
        # Out with the old; in with the new.
        my $old_value = $self->get_attribute($attr, $vertex, $successor);

        # Reset the edge value.
        $self->set_attribute($attr, $vertex, $successor, $value);
$self->_debug("$vertex =($value)=> $successor: new vertex $attr set");

        # Adjust the graph and vertex value if we made a change.
        if ($old_value != $value) {
            my $graph_value = $self->get_attribute($attr);
            $graph_value += $value - $old_value;
$self->_debug("adjust the graph $attr to $graph_value");
            $self->set_attribute($attr, $graph_value);

            my $vertex_value = $self->get_attribute($attr, $vertex);
            $vertex_value += $value - $old_value;
$self->_debug("adjust the vertex $attr to $vertex_value");
            $self->set_attribute($attr, $vertex, $vertex_value);
        }
    }
    elsif (!$self->has_attribute($attr, $vertex, $successor)) {
        $value = $self->{data}{$attr}{$vertex}{$successor};
$self->_debug("$attr from the data is $value");
        $self->set_attribute($attr, $vertex, $successor, $value);
    }

$self->_debug('exiting edge_attr');
    return $self->get_attribute($attr, $vertex, $successor);
}  # }}}

sub heaviest_vertices { shift->largest_vertices(WEIGHT) }
sub largest_vertices {  # {{{
    my ($self, $attr) = @_;
    # Use the default attribute if not given one.
    $attr ||= $self->{attr};
$self->_debug("entering largest_vertices for $attr");

    my $key = 'largest_'. $attr .'_vertices';

    unless (defined $self->{$key}) {
        $self->{$key} = [];

        my $largest = 0;

        for ($self->vertices) {
            my $value = $self->vertex_attr(
                vertex => $_,
                attr   => $attr,
            );
$self->_debug("vertex_attr($_, $attr) = $value");

            if (!defined $largest || $value > $largest) {
                $largest = $value;
                $self->{$key} = [ $_ ];
            }
            elsif ($value == $largest) {
                push @{ $self->{$key} }, $_;
            }
        }
    }

$self->_debug('exiting largest_vertices with ['. join (', ', @{ $self->{$key} }) . ']');
    return $self->{$key};
}  # }}}

sub lightest_vertices { shift->smallest_vertices(WEIGHT) }
sub smallest_vertices {  # {{{
    my ($self, $attr) = @_;
    # Use the default attribute if not given one.
    $attr ||= $self->{attr};
$self->_debug("entering smallest_vertices for $attr");

    my $key = 'smallest_'. $attr .'_vertices';

    unless (defined $self->{$key}) {
        $self->{$key} = [];

        my $smallest;

        for ($self->vertices) {
            my $value = $self->vertex_attr(
                vertex => $_,
                attr   => $attr,
            );
$self->_debug("vertex_attr($_, $attr) = $value");

            if (!defined $smallest || $value < $smallest) {
                $smallest = $value;
                $self->{$key} = [ $_ ];
            }
            elsif ($value == $smallest) {
                push @{ $self->{$key} }, $_;
            }
        }
    }

$self->_debug('exiting smallest_vertices with ['. join (', ', @{ $self->{$key} }) . ']');
    return $self->{$key};
}  # }}}

sub max_weight { shift->max_attr(WEIGHT) }
sub max_attr {  # {{{
    my ($self, $attr) = @_;
    # Use the default attribute if not given one.
    $attr ||= $self->{attr};

    return $self->vertex_attr(
        vertex => $self->largest_vertices($attr)->[0],
        attr   => $attr,
    );
}  # }}}

sub min_weight { shift->min_attr(WEIGHT) }
sub min_attr {  # {{{
    my ($self, $attr) = @_;
    # Use the default attribute if not given one.
    $attr ||= $self->{attr};

    return $self->vertex_attr(
        vertex => $self->smallest_vertices($attr)->[0],
        attr   => $attr,
    );
}  # }}}

1;

__END__

=head1 NAME

Graph::Weighted - An abstract, weighted graph implementation

=head1 SYNOPSIS

  use Graph::Weighted;

  $g = Graph::Weighted->new(
      data => [
        [ 0, 1, 2, 0, 0 ],  # A vertex with two edges.
        [ 1, 0, 3, 0, 0 ],  # "
        [ 2, 3, 0, 0, 0 ],  # "
        [ 0, 0, 1, 0, 0 ],  # A vertex with one edge.
        [ 0, 0, 0, 0, 0 ]   # A vertex with no edges.
      ]
  );

  $g = Graph::Weighted->new(
      data => {
          weight => {
              a => { b => 1, c => 2 },  # A vertex with two edges.
              b => { a => 1, c => 3 },  # "
              c => { a => 2, b => 3 },  # "
              d => { c => 1 },          # A vertex with one edge.
              e => {}                   # A vertex with no edges.
          }
          foo => [
              [ 1, 2, 3 ],
              [ 4, 5, 6 ],
              [ 7, 8, 9 ]
          ],
     }
  );

  $g = Graph::Weighted->new(
      data => $Math_Matrix_object,
      retrieve_as => 'ARRAY',
  );

  $data = $g->weight_data;

  $w = $g->graph_weight;

  $w = $g->vertex_weight($v1);
  $w = $g->vertex_weight($v1, $w + 1);

  $w = $g->edge_weight($v1, $v2);
  $w = $g->edge_weight($v1, $v2, $w + 1);

  $vertices = $g->heaviest_vertices;
  $vertices = $g->lightest_vertices;

  $w = $g->max_weight;  # Weight of the largest vertices.
  $w = $g->min_weight;  # Weight of the smallest vertices.

  # Call the weight methods of the inherited Graph module.
  $x = $g->MST_Kruskal;
  $x = $g->APSP_Floyd_Warshall;
  $x = $g->MST_Prim($p);

=head1 DESCRIPTION

A C<Graph::Weighted> object represents a subclass of 
C<Graph::Directed> with weighted attributes that are taken from a two 
dimensional matrix of numerical values.

This module can use a standard array or hash reference for data.  It 
can also load the matrix portions of C<Math::Matrix>, 
C<Math::MatrixReal>, and C<Math::MatrixBool> objects.

Initially, the weights of the vertices are set to the sum of their 
outgoing edge weights.  This is mutable, however, and can be reset to 
any value desired, after initialization, with the C<vertex_weight> 
and C<edge_weight> methods.

This module allows you to create a graph with edges that have values 
defined in a given matrix.  You can have as many of these matrices as 
you like.  Each one is referenced by an attribute name.  For a 
weighted graph, this attribute is named "weight".  For a capacity 
graph, this attribute is named "capacity".  Each attribute corresponds
to one matrix of values.

=head1 PUBLIC METHODS

=over 4

=item * new %ARGUMENTS

=over 4

=item debug => 0 | 1

Flag to invoke verbose mode while processing.  Defaults to zero.

=item zero_edges => 0 | 1

Flag to add edges between vertices with a weight of zero.  Defaults to 
zero.

=item default_attribute => STRING

The attribute to use by default, if the generic (C<load>, C<data>, 
and C<*_attr>) methods are called without an attribute as an 
argument (which should never actually happen, if you are doing thing 
corrdctly).

This is set to 'weight', by default, of course.

=item data => $HASHREF | $ARRAYREF | $OBJECT

Two dimensional hash, (NxN) array, or known object reference to use 
for vertices and weighted edges.

C<Math::Matrix>, C<Math::MatrixReal>, and C<Math::MatrixBool> objects 
can also be loaded.

=item retrieve_as => 'HASH' | 'ARRAY'

Flag to tell the C<weight_data> method to output as a hash or array
reference.  Defaults to C<HASH>.

If this object attribute is set to C<ARRAY>, the C<zero_edges> 
attribute is automatically turned on.

=back

=item * load_weights $HASHREF | $ARRAYREF | $OBJECT

Turn the given two dimensional hash, (NxN) array, or object reference 
into the vertices and weighted edges of a C<Graph::Directed> object.

C<Math::Matrix>, C<Math::MatrixReal>, and C<Math::MatrixBool> objects 
can also be loaded.

=item * weight_data

Return a two dimensional representation of the vertices and all their 
weighted edges.

The representation can be either a hash or array reference, depending
on the C<retrieve_as> object attribute setting.

=item * graph_weight

Get the total weight of the graph, which is the sum of the vertex 
weights.

=item * vertex_weight $VERTEX [, $WEIGHT]

Return the weight of a vertex.

(The vertices are just the keys of the data, not some glorified 
object, by the way.)

If a second argument is provided, the vertex weight is set to that 
value and is distributed evenly to the vertex's outgoing edges, and 
the total weight of the graph is adjusted accordingly.

=item * edge_weight $VERTEX, $SUCCESSOR [, $WEIGHT]

Return the weight of an edge between the two given vertices.

If a third argument is provided, the weight it represents is used
to replace the weight of the edge between the vertex (first argument)
and it's successor (second argument).  Finally, the weight of the 
vertex and the total weight of the graph are adjusted accordingly.

=item * heaviest_vertices

Return an array reference of vertices with the most weight.

=item * lightest_vertices

Return an array reference of vertices with the least weight.

=item * max_weight

Return the weight of the heaviest vertices.

=item * min_weight

Return the weight of the lightest vertices.

=back

=head1 PRIVATE METHODS

=over 4

=item * _debug @STUFF

Print the contents of the argument array with a newline appended.

=back

=head1 API METHODS

This section briefly describes the methods to use when creating your
own, custom subclass of C<Graph::Weighted>.  Please see the
C<Graph::Weighted::Capacity> module for a simple example.

These are generic methods used in the public methods of
C<Graph::Weighted> and C<Graph::Weighted::Capacity>.  Primarily, they
each accept an extra attribute argument and use the class default 
attribute, if none is provided.

Please remember that the C<default_attribute> should probably be set,
even though it is not required.  Also, it is recommended that you
specifically call your methods with an attribute (shown as C<[$ATTR]> 
below), even though you may have already defined a default.  This is 
to avoid the mixups that result in "multi-attributed" graphs, where 
the default may be something other than the data attribute of
interest.

All the following methods are described in greater detail under the 
C<PUBLIC METHODS> section, above.

=over 4

=item * new %ARGS

Using a default attribute and an array reference:

  $g = Graph::Weighted::Foo->new(
      default_attribute => 'foo',
      data => $array_ref,
  );

Using a set of data (which can be either array or hash references), 
with keys as attributes:

  $g = Graph::Weighted::Bar->new(
      data => {
          foo => $data_1,
          bar => $data_2,
          baz => $data_3,
      },
  );

=item * load $DATA [, $ATTR]

This method can accept either a C<Math::Matrix*> object, an array or 
hash reference for the data.

If given an array reference, the attribute argument or class default
attribute is used.

If given a hash reference, the keys are used as attributes and the 
values can be either C<Math::Matrix*> objects, array or hash 
references.

=item * data [$ATTR]

  $data = $g->data($attr);

Return a two dimensional representation of the vertices and all their 
valued edges.

The representation can be either a hash or array reference, depending
on the C<retrieve_as> object attribute setting.

=item * graph_attr [$ATTR]

  $x = $g->graph_attr($attr);

=item * vertex_attr $VERTEX [, $VALUE] [, $ATTR]

This method requires named parameters.

  $x = $g->vertex_attr(
      vertex => $v,
      value => $val,
      attr => $attr,
  );

=item * edge_attr $VERTEX, $SUCCESSOR [, $VALUE] [, $ATTR]

This method requires named parameters.

  $x = $g->edge_attr(
      vertex => $v,
      successor => $s,
      value => $val,
      attr => $attr,
  );

=item * largest_vertices [$ATTR]

  $array_ref = $g->largest_vertices($attr);

=item * smallest_vertices [$ATTR]

  $array_ref = $g->smallest_vertices($attr);

=item * max_attr [$ATTR]

  $x = $g->max_attr($attr);

=item * min_attr [$ATTR]

  $x = $g->min_attr($attr);

=back

=head1 SEE ALSO

L<Graph::Base>

L<Graph::Weighted::Capacity>

=head1 TO DO

Handle arbitrary string attribute values.

Handle algebraic expression attribute values (probably via 
C<Math::Symbolic>).  Lisp expressions come to mind also...

That is, use some sort of callback to update values, instead of
addition and subtraction.

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
