use Test::More tests => 51;
BEGIN { use_ok 'Graph::Weighted' };

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

my $g;

# basic creation
eval {
    $g = Graph::Weighted->new(
#        debug => 1,
    );
};
isa_ok $g, 'Graph::Weighted';
ok !$@, 'created a G::W object with no arguments';

# loading and LoL -> HoH
$g = Graph::Weighted->new(
#    debug => 1,
);
eval { $g->load($matrix) };
ok !$@, 'LoL load succeeded';
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
is $g->edge_weight(4, $_), 0, "4 =(0)=> $_: edge weight defined"
    for sort keys %$data;

# Math::MatrixReal
SKIP: {
    eval { require Math::MatrixReal };
    skip "Math::MatrixReal not installed", 1 if $@;
    eval {
        $g = Graph::Weighted->new(
#            debug => 1,
            data => Math::MatrixReal->new_from_rows([[1, 2], [3, 4]]),
        );
    };
    ok !$@, 'Math::MatrixReal object creation succeeded';
}

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
eval {
    $g = Graph::Weighted->new(
#        debug => 1,
        zero_edges => 1,
        data => {
            a => { a => 0, b => 1, c => 2, },
            b => { a => 1, c => 3, },
            c => { a => 2, b => 3, },
            d => { c => 1, },
            e => {},
        },
    );
};
ok !$@, 'zero_edges object creation with HoH succeeded';

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

# Set the vertices used.
my ($p, $q, $r) = qw(a b c);

# adjust vertex weight up
my $e = 1.33333333333333;
my $x = $g->vertex_weight($p);
is $x, 3, 'vertex weight known';
my $y = $g->vertex_weight($p, $x + 1);
ok $y == $x + 1, 'vertex weight adjusted up';
is_deeply $g->data->{$p}, { $p => $e, $q => $e, $r => $e, },
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
is_deeply $g->data->{$p}, { $p => $e, $q => $e, $r => $e, },
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
is $g->data->{a}{b}, 2, 'outgoing edge weight adjusted up';
is $g->vertex_weight('a'), $v + 1, 'vertex weight adjusted up';
is $g->graph_weight, $w + 1, 'graph weight adjusted up';

# adjust edge weight down
$w = $g->graph_weight;
$v = $g->vertex_weight($p);
$x = $g->edge_weight($p, $q);
$y = $g->edge_weight($p, $q, $x - 1);
ok $y == $x - 1, 'edge weight adjusted down';
is $g->data->{$p}{$q}, 1, 'outgoing edge weight adjusted down';
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
