use Test::More tests => 58;
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
#        debug => 1,
        data => [],
    );
};
isa_ok $g, GW, 'with empty arrayref data';
$g = eval {
    Graph::Weighted->new(
#        debug => 1,
        data => {},
    );
};
isa_ok $g, GW, 'with empty hashref data';

# loading and LoL -> HoH
$g = Graph::Weighted->new(
#    debug => 1,
);
eval { $g->load($matrix) };
ok !$@, 'LoL load';
is_deeply $g->data, $data, 'HoH constructed from LoL';

# zero_edges
$g = Graph::Weighted->new(
#    debug => 1,
    zero_edges => 1,
);
$g->load($matrix);
$data = {
    0 => { 0 => 0, 1 => 1, 2 => 2, 3 => 0, 4 => 0, },
    1 => { 0 => 1, 1 => 0, 2 => 3, 3 => 0, 4 => 0, },
    2 => { 0 => 2, 1 => 3, 2 => 0, 3 => 0, 4 => 0, },
    3 => { 0 => 0, 1 => 0, 2 => 1, 3 => 0, 4 => 0, },
    4 => { 0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, },
};
is_deeply $g->data, $data, 'zero_edges HoH constructed from LoL';
is $g->edge_attr(vertex => 4, successor => $_),
    0, "4 =(0)=> $_: edge attr defined"
    for sort keys %$data;

# Matrix objects  {{{
SKIP: {
    $data = [ [1, 2], [3, 4] ];
    eval { require Math::Matrix };
    skip "Math::Matrix not installed", 1 if $@;
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
    skip "Math::MatrixReal not installed", 1 if $@;
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
    skip "Math::MatrixBool not installed", 1 if $@;
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
    $g->load(
        [ [ 0, 1 ],
          [ 1, 0, 3 ],
          [ 2, 3, 0 ], ],
    );
};
ok $@, 'non-square LoL load failed properly';

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
    ok defined $n, "$p =($n)=> $q: edge attr defined";
}
# Misc
my $w = $g->graph_attr;
is $w, 13, 'graph_attr computed';
is_deeply $g->smallest_vertices, ['e'], 'smallest vertices computed';
is_deeply $g->largest_vertices, ['c'], 'largest vertices computed';
is $g->min_attr, 0, 'min attr calculated';
is $g->max_attr, 5, 'max attr calculated';

# Set the vertices used.
my ($p, $q, $r) = qw(a b c);

# adjust vertex attr up
my $e = 1.33333333333333;
my $x = $g->vertex_attr(vertex => $p);
is $x, 3, 'vertex attr known';
my $y = $g->vertex_attr(vertex => $p, value => $x + 1);
ok $y == $x + 1, 'vertex attr adjusted up';
is_deeply $g->data->{$p}, { $p => $e, $q => $e, $r => $e, },
    'distributed outgoing attr up';
is $g->edge_attr(vertex => $p, successor => $p),
    $e, "$p => $p edge attr adjusted up";
is $g->edge_attr(vertex => $p, successor => $q),
    $e, "$p => $q edge attr adjusted up";
is $g->edge_attr(vertex => $p, successor => $r),
    $e, "$p => $r edge attr adjusted up";
is $g->graph_attr, $w + 1, 'graph attr adjusted up';

# adjust vertex attr down
$e = 1;
$w = $g->graph_attr;
$x = $g->vertex_attr(vertex => $p);
$y = $g->vertex_attr(vertex => $p, value => $x - 1);
ok $y == $x - 1, 'vertex attr adjusted down';
is_deeply $g->data->{$p}, { $p => $e, $q => $e, $r => $e, },
    'distributed outgoing attr down';
is $g->edge_attr(vertex => $p, successor => $p),
    $e, "$p => $p edge attr adjusted down";
is $g->edge_attr(vertex => $p, successor => $q),
    $e, "$p => $q edge attr adjusted down";
is $g->edge_attr(vertex => $p, successor => $r),
    $e, "$p => $r edge attr adjusted down";
is $g->graph_attr, $w - 1, 'graph_attr adjusted down';

# adjust edge attr up
$w = $g->graph_attr;
my $v = $g->vertex_attr(vertex => $p);
$x = $g->edge_attr(vertex => $p, successor => $q);
$y = $g->edge_attr(vertex => $p, successor => $q, value => $x + 1);
is $x, 1, 'edge attr known';
ok $y == $x + 1, 'edge attr adjusted up';
is $g->data->{a}{b}, 2, 'outgoing edge attr adjusted up';
is $g->vertex_attr(vertex => 'a'),
    $v + 1, 'vertex attr adjusted up';
is $g->graph_attr, $w + 1, 'graph attr adjusted up';

# adjust edge attr down
$w = $g->graph_attr;
$v = $g->vertex_attr(vertex => $p);
$x = $g->edge_attr(vertex => $p, successor => $q);
$y = $g->edge_attr(vertex => $p, successor => $q, value => $x - 1);
ok $y == $x - 1, 'edge attr adjusted down';
is $g->data->{$p}{$q}, 1, 'outgoing edge attr adjusted down';
is $g->vertex_attr(vertex => $p),
    $v - 1, 'vertex attr adjusted down';
is $g->graph_attr, $w - 1, 'graph attr adjusted down';

# Make sure we can call appropriate Graph methods.
my $z;
eval { $z = $g->MST_Kruskal };
ok !$@, 'MST_Kruskal worked';
eval { $z = $g->APSP_Floyd_Warshall };
ok !$@, 'APSP_Floyd_Warshall worked';
eval { $z = $g->MST_Prim('a') };
ok !$@, 'MST_Prim worked';

my $attr = 'foo';
$g = eval {
    Graph::Weighted->new(
#        debug => 1,
#        zero_edges => 1,
        data => $matrix,
        default_attribute => $attr,
    );
};
isa_ok $g, GW, "with arbitrary attribute default of $attr";
$x = $g->vertex_attr(vertex => 0);
is $x, 3, "vertex $attr known";
