use Test::More 'no_plan';#tests => 1;
BEGIN { use_ok 'Graph::Weighted' };

my $g = Graph::Weighted->new(
#    debug => 1,
);
isa_ok $g, 'Graph::Weighted';

eval {
    $g->load(
        [ [ 0, 1, 2 ],
          [ 1, 0, 3 ],
          [ 2, 3, 0 ], ],
    );
};
ok !$@, 'LoL load succeeded';

my $data = {
    0 => { 0 => 0, 1 => 1, 2 => 2 },
    1 => { 0 => 1, 1 => 0, 2 => 3 },
    2 => { 0 => 2, 1 => 3, 2 => 0 }
};
is_deeply $g->matrix, $data, 'HoH constructed from LoL';

eval {
    $g->load(
        [ [ 0, 1 ],
          [ 1, 0, 3 ],
          [ 2, 3, 0 ], ],
    );
};
ok $@, 'non-square LoL load failed properly';

$g->reset_graph;
my @v = $g->vertices;
ok !@v, 'graph reset';

eval {
    $g = Graph::Weighted->new(
#        debug => 1,
        data => {
            a => { a => 0, b => 1, c => 2, },
            b => { a => 1, c => 3, },
            c => { a => 2, b => 3, },
            d => { c => 1, },
            e => {},
        },
    );
};
ok !$@, 'object creation HoH load succeeded';

my @e = $g->edges();
ok @e, 'graph has edges';

while (@e) {
    my ($p, $q) = (shift (@e), shift (@e));
    my $n = $g->get_attribute('weight', $p, $q);
    ok defined $n, "$p =($n)=> $q: edge weight defined";
}

my $w = $g->graph_weight;
is $w, 13, 'graph_weight computed';
is_deeply $g->lightest_vertices, ['e'], 'lightest_vertices computed';
is_deeply $g->heaviest_vertices, ['c'], 'heaviest_vertices computed';

eval {
    $g->reset_graph;

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
ok !$@, 'zero_edges object creation succeeded';

my $x = $g->vertex_weight('a');
is $x, 3, 'vertex_weight known';
my $y = $g->vertex_weight('a', $x + 1);
ok $y == $x + 1, 'vertex_weight adjusted up';
is_deeply $g->matrix->{a},
    { a => 1.33333333333333, b => 1.33333333333333, c => 1.33333333333333, },
    'distributed outgoing weight up';
is $g->edge_weight('a', 'a'), 1.33333333333333, 'a->a edge_weight adjusted up';
is $g->edge_weight('a', 'b'), 1.33333333333333, 'a->b edge_weight adjusted up';
is $g->edge_weight('a', 'c'), 1.33333333333333, 'a->c edge_weight adjusted up';
is $g->graph_weight, $w + 1, 'graph_weight adjusted up';

$w = $g->graph_weight;
$x = $g->vertex_weight('a');
$y = $g->vertex_weight('a', $x - 1);
ok $y == $x - 1, 'vertex_weight adjusted down';
is_deeply $g->matrix->{a}, { a => 1, b => 1, c => 1, },
    'distributed outgoing weight down';
is $g->edge_weight('a', 'a'), 1, 'a->a edge_weight adjusted down';
is $g->edge_weight('a', 'b'), 1, 'a->b edge_weight adjusted down';
is $g->edge_weight('a', 'c'), 1, 'a->c edge_weight adjusted down';
is $g->graph_weight, $w - 1, 'graph_weight adjusted down';

$w = $g->graph_weight;
my $v = $g->vertex_weight('a');
$x = $g->edge_weight('a', 'b');
is $x, 1, 'edge_weight known';
$y = $g->edge_weight('a', 'b', $x + 1);
ok $y == $x + 1, 'edge_weight adjusted up';
is $g->matrix->{a}{b}, 2, 'outgoing edge weight adjusted up';
is $g->vertex_weight('a'), $v + 1, 'vertex_weight adjusted up';
is $g->graph_weight, $w + 1, 'graph_weight adjusted up';

$w = $g->graph_weight;
my $v = $g->vertex_weight('a');
$x = $g->edge_weight('a', 'b');
$y = $g->edge_weight('a', 'b', $x - 1);
ok $y == $x - 1, 'edge_weight adjusted up';
is $g->matrix->{a}{b}, 1, 'outgoing edge weight adjusted up';
is $g->vertex_weight('a'), $v - 1, 'vertex_weight adjusted up';
is $g->graph_weight, $w - 1, 'graph_weight adjusted up';
