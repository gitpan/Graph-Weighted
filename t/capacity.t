use Test::More tests => 53;

BEGIN { use_ok 'Graph::Weighted::Capacity' };

use constant GWC => 'Graph::Weighted::Capacity';

my $matrix = [
    [ 0, 1, 2, 0, 0, ],
    [ 1, 0, 3, 0, 0, ],
    [ 2, 3, 0, 0, 0, ],
    [ 0, 0, 1, 0, 0, ],
    [ 0, 0, 0, 0, 0, ],
];
my $data = {
    0 => { 1 => 1, 2 => 2, },
    1 => { 0 => 1, 2 => 3, },
    2 => { 0 => 2, 1 => 3, },
    3 => { 2 => 1, },
    4 => {},
};

# basic creation
my $g = eval {
    Graph::Weighted::Capacity->new(
#        debug => 1,
    );
};
isa_ok $g, GWC, 'with no arguments';

# creation with empty data references.
$g = eval {
    Graph::Weighted::Capacity->new(
    #    debug => 1,
        data => [],
    );
};
isa_ok $g, GWC, 'with empty arrayref data';
$g = eval {
    Graph::Weighted::Capacity->new(
    #    debug => 1,
        data => {},
    );
};
isa_ok $g, GWC, 'with empty hashref data';

# loading and LoL -> HoH
$g = Graph::Weighted::Capacity->new(
#    debug => 1,
);
eval { $g->load_capacity($matrix) };
ok !$@, 'LoL load_capacity';
is_deeply $g->capacity_data, $data, 'HoH constructed from LoL';

# zero_edges
$g = Graph::Weighted::Capacity->new(
#    debug => 1,
    zero_edges => 1,
);
$g->load_capacity($matrix);
$data = {
    0 => { 0 => 0, 1 => 1, 2 => 2, 3 => 0, 4 => 0, },
    1 => { 0 => 1, 1 => 0, 2 => 3, 3 => 0, 4 => 0, },
    2 => { 0 => 2, 1 => 3, 2 => 0, 3 => 0, 4 => 0, },
    3 => { 0 => 0, 1 => 0, 2 => 1, 3 => 0, 4 => 0, },
    4 => { 0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, },
};
is_deeply $g->capacity_data, $data, 'zero_edges HoH constructed from LoL';
is $g->edge_capacity(4, $_), 0, "4 =(0)=> $_: edge capacity defined"
    for sort keys %$data;

# Matrix objects  {{{
SKIP: {
    $data = [ [1, 2], [3, 4] ];
    eval { require Math::Matrix };
    skip "Math::Matrix not installed", 1 if $@;
    $g = eval {
        Graph::Weighted::Capacity->new(
#            debug => 1,
            data => Math::Matrix->new($data),
        );
    };
    isa_ok $g, GWC, 'Math::Matrix object data';
}
SKIP: {
    $data = [ [1, 2], [3, 4] ];
    eval { require Math::MatrixReal };
    skip "Math::MatrixReal not installed", 1 if $@;
    $g = eval {
        Graph::Weighted::Capacity->new(
#            debug => 1,
            data => Math::MatrixReal->new_from_rows($data),
        );
    };
    isa_ok $g, GWC, 'Math::MatrixReal object data';
}
SKIP: {
    eval { require Math::MatrixBool };
    skip "Math::MatrixBool not installed", 1 if $@;
    $g = eval {
        Graph::Weighted::Capacity->new(
#            debug => 1,
            data => Math::MatrixBool->new_from_string(
                "[ 1 0 0 ]\n[ 1 1 0 ]\n[ 1 1 1 ]\n"
            ),
        );
    };
    isa_ok $g, GWC, 'Math::MatrixBool object data';
}  # }}}

# non-square
eval {
    $g->load_capacity(
        [ [ 0, 1 ],
          [ 1, 0, 3 ],
          [ 2, 3, 0 ], ],
    );
};
ok $@, 'non-square LoL load_capacity failed properly';

# create with HoH
$g = eval {
    Graph::Weighted::Capacity->new(
#        debug => 1,
        zero_edges => 1,
        data => {
            'capacity' => {
                a => { a => 0, b => 1, c => 2, },
                b => { a => 1, c => 3, },
                c => { a => 2, b => 3, },
                d => { c => 1, },
                e => {},
            },
        },
    );
};
isa_ok $g, GWC, 'zero_edges HoH';

# Edges? We don' need no steenking edges!
my @e = $g->edges();
ok @e, "Edges? We don' need no steenking edges!";
while (@e) {
    my ($p, $q) = (shift (@e), shift (@e));
    my $n = $g->get_attribute('capacity', $p, $q);
    ok defined $n, "$p =($n)=> $q: edge capacity defined";
}
# Misc
my $w = $g->graph_capacity;
is $w, 13, 'graph_capacity computed';
is_deeply $g->smallest_vertices, ['e'], 'smallest vertices computed';
is_deeply $g->largest_vertices, ['c'], 'largest vertices computed';
is $g->min_capacity, 0, 'min capacity calculated';
is $g->max_capacity, 5, 'max capacity calculated';

# Set the vertices used.
my ($p, $q, $r) = qw(a b c);

# adjust vertex capacity up
my $e = 1.33333333333333;
my $x = $g->vertex_capacity($p);
is $x, 3, 'vertex capacity known';
my $y = $g->vertex_capacity($p, $x + 1);
ok $y == $x + 1, 'vertex capacity adjusted up';
is_deeply $g->capacity_data->{$p}, { $p => $e, $q => $e, $r => $e, },
    'distributed outgoing capacity up';
is $g->edge_capacity($p, $p), $e, "$p => $p edge capacity adjusted up";
is $g->edge_capacity($p, $q), $e, "$p => $q edge capacity adjusted up";
is $g->edge_capacity($p, $r), $e, "$p => $r edge capacity adjusted up";
is $g->graph_capacity, $w + 1, 'graph capacity adjusted up';

# adjust vertex capacity down
$e = 1;
$w = $g->graph_capacity;
$x = $g->vertex_capacity($p);
$y = $g->vertex_capacity($p, $x - 1);
ok $y == $x - 1, 'vertex capacity adjusted down';
is_deeply $g->capacity_data->{$p}, { $p => $e, $q => $e, $r => $e, },
    'distributed outgoing capacity down';
is $g->edge_capacity($p, $p), $e, "$p => $p edge capacity adjusted down";
is $g->edge_capacity($p, $q), $e, "$p => $q edge capacity adjusted down";
is $g->edge_capacity($p, $r), $e, "$p => $r edge capacity adjusted down";
is $g->graph_capacity, $w - 1, 'graph_capacity adjusted down';

# adjust edge capacity up
$w = $g->graph_capacity;
my $v = $g->vertex_capacity($p);
$x = $g->edge_capacity($p, $q);
$y = $g->edge_capacity($p, $q, $x + 1);
is $x, 1, 'edge capacity known';
ok $y == $x + 1, 'edge capacity adjusted up';
is $g->capacity_data->{a}{b}, 2, 'outgoing edge capacity adjusted up';
is $g->vertex_capacity('a'), $v + 1, 'vertex capacity adjusted up';
is $g->graph_capacity, $w + 1, 'graph capacity adjusted up';

# adjust edge capacity down
$w = $g->graph_capacity;
$v = $g->vertex_capacity($p);
$x = $g->edge_capacity($p, $q);
$y = $g->edge_capacity($p, $q, $x - 1);
ok $y == $x - 1, 'edge capacity adjusted down';
is $g->capacity_data->{$p}{$q}, 1, 'outgoing edge capacity adjusted down';
is $g->vertex_capacity($p), $v - 1, 'vertex capacity adjusted down';
is $g->graph_capacity, $w - 1, 'graph capacity adjusted down';
