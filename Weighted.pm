package Graph::Weighted;
use strict;
use Carp;
use vars qw($VERSION); $VERSION = '0.04';
use base qw(Graph::Directed);

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

sub load {  # {{{
    my ($self, $data) = @_;
$self->_debug('entering load with a '. ref ($data) . ' object');

    if (ref ($data) eq 'Math::MatrixReal' ||
        ref ($data) eq 'Math::Matrix'
    ) {
        # Math::Matrix* objects are LoLs and have the matrix as the
        # first element.
        $data = $data->[0];
    }

    if (ref ($data) eq 'Math::MatrixBool') {
        # Math::MatrixBool objects are actually Bit::Vectors, that
        # can be output by "stringification, like this:
        # [ 1 0 0 ]
        # [ 1 1 0 ]
        # [ 1 1 1 ]
        # So de-stringification gymnastics have to happen.  Ugh.
        $data = [
            map { [ split ] }
                sprintf ('%s', "$data") =~ /\[\s([\d\s]*)\s\]/gs
        ];
    }

    # We are given a HoH.
    if (ref ($data) eq 'HASH') {
        # Set the vertices and weighted edges.
        while (my ($vertex, $successors) = each %$data) {
            # Add an "edgeless vertex" if there are no successors or
            # successors all have zero values.
            my $weight = 0;
            $weight += $_ for values %$successors;
$self->_debug("$vertex weight = $weight");

            unless (keys %$successors && ($weight || $self->{zero_edges})) {
$self->_debug("$vertex edgeless");
                $self->add_vertex($vertex);
            }

            while (my ($successor, $n) = each %$successors) {
$self->_debug("$vertex =($n)=> $successor");
                $self->add_weighted_edge($vertex, $n, $successor)
                    if $self->{zero_edges} || $n != 0;
            }
        }
    }
    # We are given a LoL.
    elsif (ref ($data) eq 'ARRAY') {
        # Initialize the object data.
        $self->{data} = {};

        # Set the vertices and weighted edges.
        for my $vertex (0 .. @$data - 1) {
            croak "Incorrectly sized array\n"
                unless @{ $data->[$vertex] } == @$data;

            my $weight = 0;
            $weight += $_ for @{ $data->[$vertex] };
$self->_debug("$vertex weight = $weight");

            unless ($weight || $self->{zero_edges}) {
$self->_debug("$vertex edgeless");
                $self->add_vertex($vertex);
                $self->{data}{$vertex} = {};
            }

            for my $successor (0 .. @{ $data->[$vertex] } - 1) {
                my $n = $data->[$vertex][$successor];

                if ($n || $self->{zero_edges}) {
$self->_debug("$vertex =($n)=> $successor");
                    $self->add_weighted_edge($vertex, $n, $successor);

                    $self->{data}{$vertex}{$successor} = $n;
                }
            }
        }
    }
    else {
        croak "Unknown data format\n";
    }
$self->_debug('exiting load');
}  # }}}

sub data {  # {{{
    return shift->{data};
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

        # How many successors does the vertex have?
        my $n_successors = keys %{ $self->{data}{$vertex} };

        # Distribute the weight to all outgoing edges.
        my $new_weight = $weight / $n_successors;
        for my $successor (keys %{ $self->{data}{$vertex} }) {
            # Reset the data value.
            $self->{data}{$vertex}{$successor} = $new_weight;
            # Reset the outgoing edge.
            $self->set_attribute(WEIGHT, $vertex, $successor, $new_weight);
$self->_debug("$vertex =($new_weight)=> $successor: new vertex weight set");
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
        $weight += $_ for values %{ $self->{data}{$vertex} };
        $weight = 0 unless $weight;
$self->_debug("weight computed as $weight");
        $self->set_attribute(WEIGHT, $vertex, $weight);
    }

$self->_debug('exiting vertex_weight');
    return $self->get_attribute(WEIGHT, $vertex);
}  # }}}

sub edge_weight {  # {{{
    my ($self, $vertex, $successor, $weight) = @_;
$self->_debug("entering edge_weight with $vertex and $successor");

    if (defined $weight) {
$self->_debug("weight is defined as $weight");
        # Out with the old; in with the new.
        my $old = $self->get_attribute(WEIGHT, $vertex, $successor);

        # Reset the edge weight.
        $self->set_attribute(WEIGHT, $vertex, $successor, $weight);

        # Reset the data value.
        $self->{data}{$vertex}{$successor} = $weight;
$self->_debug("$vertex =($weight)=> $successor: new vertex weight set");

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
    elsif (!$self->has_attribute(WEIGHT, $vertex, $successor)) {
        $weight = $self->{data}{$vertex}{$successor};
$self->_debug("weight from the data is $weight");
        $self->set_attribute(WEIGHT, $vertex, $successor, $weight);
    }

$self->_debug('exiting edge_weight');
    return $self->get_attribute(WEIGHT, $vertex, $successor);
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
          a => { b => 1, c => 2, },  # A vertex with two edges.
          b => { a => 1, c => 3, },  # "
          c => { a => 2, b => 3, },  # "
          d => { c => 1, },          # A vertex with one edge.
          e => {},                   # A vertex with no edges.
     }
  );

  $g = Graph::Weighted->new(data => $object);  # See documentation.

  $g = Graph::Weighted->new();
  $g->load(
      [ [ 0, 1, 2, 0, 0, ],    # A vertex with two edges.
        [ 1, 0, 3, 0, 0, ],    # "
        [ 2, 3, 0, 0, 0, ],    # "
        [ 0, 0, 1, 0, 0, ],    # A vertex with one edge.
        [ 0, 0, 0, 0, 0, ], ]  # A vertex with no edges.
  );

  $data = $g->data;

  $w = $g->graph_weight;

  $w = $g->vertex_weight($p);
  $w = $g->vertex_weight($p, $w + 1);

  $w = $g->edge_weight($p, $q);
  $w = $g->edge_weight($p, $q, $w + 1);

  $heavies = $g->heaviest_vertices;
  $lights  = $g->lightest_vertices;

  # Call any methods of the inherited Graph module.
  @v = $g->vertices;
  @v = $g->successors($p);  # etc.
  $z = $g->MST_Kruskal;
  $z = $g->APSP_Floyd_Warshall;
  $z = $g->MST_Prim($p);

=head1 ABSTRACT

A weighted graph implementation

=head1 DESCRIPTION

A C<Graph::Weighted> object represents a subclass of 
C<Graph::Directed> with weighted attributes that are taken from a 
two dimensional matrix (HoH or NxN LoL) of numerical values.

This module can also load the matrix portions of C<Math::Matrix>, 
C<Math::MatrixReal>, and C<Math::MatrixBool> objects.

Initially, the weights of the vertices are set to the sum of their 
outgoing edge weights.  This is mutable, however, and can be reset to 
any value desired, after initialization, with the C<vertex_weight> 
and C<edge_weight> methods.

=head1 PUBLIC METHODS

=over 4

=item new %ARGUMENTS

=over 4

=item debug => 0 | 1

Flag to invoke verbose mode while processing.  Defaults to zero.

=item zero_edges => 0 | 1

Flag to add edges between vertices with a weight of zero.  Defaults to 
zero.

=item data => $HASHREF | $ARRAYREF | $OBJECT

Two dimensional hash, (NxN) array, or known object reference to use 
for vertices and weighted edges.

The known objects are C<Math::Matrix>, C<Math::MatrixReal>, and 
C<Math::MatrixBool>.

=back

=item load $HASHREF | $ARRAYREF | $OBJECT

Turn the given two dimensional hash, (NxN) array, or known object 
reference into the vertices and weighted edges of a 
C<Graph::Directed> object.

The known objects are C<Math::Matrix>, C<Math::MatrixReal>, and 
C<Math::MatrixBool>.

=item data

Return the two dimensional hash used for vertices and weighted edges.

=item graph_weight

Get the total weight of the graph, by summing all the vertex weights.

=item vertex_weight $VERTEX [, $WEIGHT]

Return the weight of a vertex.  This method can also be used to set 
the vertex weight, if a second argument is provided.

(The vertices are just the keys of the data, not some glorified 
object.)

When the second argument is provided, the weight it represents is 
distributed evenly to the vertex's outgoing edges, and the total 
weight of the entire graph is adjusted accordingly.

=item edge_weight $VERTEX, $NEIGHBOR [, $WEIGHT]

Return the weight of an edge between the two given vertices.  This 
method can also be used to set the edge weight, if a third argument 
is provided.

(The vertices are just the keys of the data, not some glorified 
object.)

When the third argument is provided, the weight it represents is used
to replace the weight of the edge between the vertex (first argument)
and it's successor (second argument).  Lastly, the total weight of the 
entire graph and the weight of the vertex are adjusted accordingly.

=item heaviest_vertices

Return the array reference of vertices with the most weight.

=item lightest_vertices

Return the array reference of vertices with the least weight.

=back

=head1 PRIVATE METHODS

=over 4

=item _debug @STUFF

Print the contents of the argument array with a newline appended.

=back

=head1 SEE ALSO

C<Graph::Base>

=head1 TO DO

Handle "capacity graphs" as detailed in the C<Graph::Base> module.

Handle clusters of vertices and sub-graphs.

Handle Math::MatrixSparse and PDL::Matrix objects?

=head1 AUTHOR

Gene Boggs E<lt>cpan@ology.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
