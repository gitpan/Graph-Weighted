use Test::More tests => 57;
BEGIN { use_ok 'Graph::Weighted' };

use constant GW => 'Graph::Weighted';

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
    Graph::Weighted->new(
#        debug => 1,
    );
};
isa_ok $g, GW, 'with no arguments';

# creation with empty data references.
$g = eval {
    Graph::Weighted->new(
    #    debug => 1,
        data => [],
    );
};
isa_ok $g, GW, 'with empty arrayref data';
$g = eval {
    Graph::Weighted->new(
    #    debug => 1,
        data => {},
    );
};
isa_ok $g, GW, 'with empty hashref data';

# loading and LoL -> HoH
$g = Graph::Weighted->new(
#    debug => 1,
);
eval { $g->load_weight($matrix) };
ok !$@, 'LoL load_weight';
is_deeply $g->weight_data, $data, 'HoH constructed from LoL';

# return LoL data
$g = Graph::Weighted->new(
#    debug => 1,
    retrieve_as => 'ARRAY',
    data => $matrix,
);
#print join ("\n", map { "[@$_]" } @$matrix), "\n";
#print join ("\n", map { "[@$_]" } @{ $g->weight_data }), "\n";
is_deeply $g->weight_data, $matrix, 'data retrieved as LoL';

# zero_edges
$g = Graph::Weighted->new(
#    debug => 1,
    zero_edges => 1,
);
$g->load_weight($matrix);
$data = {
    0 => { 0 => 0, 1 => 1, 2 => 2, 3 => 0, 4 => 0, },
    1 => { 0 => 1, 1 => 0, 2 => 3, 3 => 0, 4 => 0, },
    2 => { 0 => 2, 1 => 3, 2 => 0, 3 => 0, 4 => 0, },
    3 => { 0 => 0, 1 => 0, 2 => 1, 3 => 0, 4 => 0, },
    4 => { 0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, },
};
is_deeply $g->weight_data, $data, 'zero_edges HoH constructed from LoL';
is $g->edge_weight(4, $_), 0, "4 =(0)=> $_: edge weight defined"
    for sort keys %$data;

# Matrix objects  {{{
SKIP: {
    $data = [ [1, 2], [3, 4] ];
    eval { require Math::Matrix };
    skip 'Math::Matrix not installed', 1 if $@;
    $g = eval {
        Graph::Weighted->new(
#            debug => 1,
            data => Math::Matrix->new($data),
        );
    };
    isa_ok $g, GW, 'Math::Matrix object data';
}
SKIP: {
    $data = [ [1, 2], [3, 4] ];
    eval { require Math::MatrixReal };
    skip 'Math::MatrixReal not installed', 1 if $@;
    $g = eval {
        Graph::Weighted->new(
#            debug => 1,
            data => Math::MatrixReal->new_from_rows($data),
        );
    };
    isa_ok $g, GW, 'Math::MatrixReal object data';
}
SKIP: {
    eval { require Math::MatrixBool };
    skip 'Math::MatrixBool not installed', 1 if $@;
    $g = eval {
        Graph::Weighted->new(
#            debug => 1,
            data => Math::MatrixBool->new_from_string(
                "[ 1 0 0 ]\n[ 1 1 0 ]\n[ 1 1 1 ]\n"
            ),
        );
    };
    isa_ok $g, GW, 'Math::MatrixBool object data';
}  # }}}

# non-square
eval {
    $g->load_weight(
        [ [ 0, 1 ],
          [ 1, 0, 3 ],
          [ 2, 3, 0 ], ],
    );
};
ok $@, 'non-square LoL load_weight failed properly';

# create with HoH
$g = eval {
    Graph::Weighted->new(
#        debug => 1,
        zero_edges => 1,
        data => {
            'weight' => {
                a => { a => 0, b => 1, c => 2, },
                b => { a => 1, c => 3, },
                c => { a => 2, b => 3, },
                d => { c => 1, },
                e => {},
            },
        },
    );
};
isa_ok $g, GW, 'zero_edges HoH';

# Edges? We don' need no steenking edges!
my @e = $g->edges();
ok @e, "Edges? We don' need no steenking edges!";
while (@e) {
    my ($p, $q) = (shift (@e), shift (@e));
    my $n = $g->get_attribute('weight', $p, $q);
    ok defined $n, "$p =($n)=> $q: edge weight defined";
}
# Misc
my $w = $g->graph_weight;
is $w, 13, 'graph_weight computed';
is_deeply $g->lightest_vertices, ['e'], 'lightest vertices computed';
is_deeply $g->heaviest_vertices, ['c'], 'heaviest vertices computed';
is $g->min_weight, 0, 'min weight calculated';
is $g->max_weight, 5, 'max weight calculated';

# Set the vertices used.
my ($p, $q, $r) = qw(a b c);

# adjust vertex weight up
my $e = 1.33333333333333;
my $x = $g->vertex_weight($p);
is $x, 3, 'vertex weight known';
my $y = $g->vertex_weight($p, $x + 1);
ok $y == $x + 1, 'vertex weight adjusted up';
is_deeply $g->weight_data->{$p}, { $p => $e, $q => $e, $r => $e, },
    'distributed outgoing weight up';
is $g->edge_weight($p, $p), $e, "$p => $p edge weight adjusted up";
is $g->edge_weight($p, $q), $e, "$p => $q edge weight adjusted up";
is $g->edge_weight($p, $r), $e, "$p => $r edge weight adjusted up";
is $g->graph_weight, $w + 1, 'graph weight adjusted up';

# adjust vertex weight down
$e = 1;
$w = $g->graph_weight;
$x = $g->vertex_weight($p);
$y = $g->vertex_weight($p, $x - 1);
ok $y == $x - 1, 'vertex weight adjusted down';
is_deeply $g->weight_data->{$p}, { $p => $e, $q => $e, $r => $e, },
    'distributed outgoing weight down';
is $g->edge_weight($p, $p), $e, "$p => $p edge weight adjusted down";
is $g->edge_weight($p, $q), $e, "$p => $q edge weight adjusted down";
is $g->edge_weight($p, $r), $e, "$p => $r edge weight adjusted down";
is $g->graph_weight, $w - 1, 'graph_weight adjusted down';

# adjust edge weight up
$w = $g->graph_weight;
my $v = $g->vertex_weight($p);
$x = $g->edge_weight($p, $q);
$y = $g->edge_weight($p, $q, $x + 1);
is $x, 1, 'edge weight known';
ok $y == $x + 1, 'edge weight adjusted up';
is $g->weight_data->{a}{b}, 2, 'outgoing edge weight adjusted up';
is $g->vertex_weight('a'), $v + 1, 'vertex weight adjusted up';
is $g->graph_weight, $w + 1, 'graph weight adjusted up';

# adjust edge weight down
$w = $g->graph_weight;
$v = $g->vertex_weight($p);
$x = $g->edge_weight($p, $q);
$y = $g->edge_weight($p, $q, $x - 1);
ok $y == $x - 1, 'edge weight adjusted down';
is $g->weight_data->{$p}{$q}, 1, 'outgoing edge weight adjusted down';
is $g->vertex_weight($p), $v - 1, 'vertex weight adjusted down';
is $g->graph_weight, $w - 1, 'graph weight adjusted down';

# Make sure we can call appropriate Graph methods.
my $z;
eval { $z = $g->MST_Kruskal };
ok !$@, 'MST_Kruskal worked';
eval { $z = $g->APSP_Floyd_Warshall };
ok !$@, 'APSP_Floyd_Warshall worked';
eval { $z = $g->MST_Prim('a') };
ok !$@, 'MST_Prim worked';