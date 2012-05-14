#!perl
use Test::More 'no_plan';

BEGIN {
    use constant GW => 'Graph::Weighted';
    use_ok GW;
};

my $weight_dataset = [
    [],                   # No nodes
    [ [ 0 ], ],           # 1 node, no edges
    [ [ 1, 0, ],          # 2 nodes w=1,1 of self-edges
      [ 0, 1, ], ],
    [ [ 0, 1, 2, 0, 0, ], # 5 nodes w=3,4,5,1,0
      [ 1, 0, 3, 0, 0, ],
      [ 2, 3, 0, 0, 0, ],
      [ 0, 0, 1, 0, 0, ],
      [ 0, 0, 0, 0, 0, ], ],
];

my $n = 0;
for my $data (@$weight_dataset) {
    my $g = eval { Graph::Weighted->new() };
    isa_ok $g, GW, $n;
    eval { $g->populate($data) };
    print $@ if $@;
    ok !$@, "populate weight data $n";
    my $g_weight = 0;
    for my $vertex ($g->vertices()) {
        my $v_weight = $g->get_weight($vertex);
        $g_weight += $v_weight;
    }
    my $w = _weight_of($data);
    is $g_weight, $w, "weight: $g_weight = $w";
    $n++;
}

my $magnitude_dataset = [
    [],                   # No nodes
    [ [ 0 ], ],           # 1 node, no edges
    [ [ 1, 0, ],          # 2 nodes w=1,1 of self-edges
      [ 0, 1, ], ],
    [ [ 0, 2, 1, 0, 0, ], # 5 nodes w=3,4,5,1,0
      [ 3, 0, 1, 0, 0, ],
      [ 3, 2, 0, 0, 0, ],
      [ 0, 0, 1, 0, 0, ],
      [ 1, 1, 1, 1, 0, ], ],
];

$n = 0;
for my $data (@$magnitude_dataset) {
    my $g = eval { Graph::Weighted->new() };
    isa_ok $g, GW, $n;
    eval { $g->populate($data, '', 'magnitude') };
    print $@ if $@;
    ok !$@, "populate magnitude data $n";
    my $g_weight = 0;
    for my $vertex ($g->vertices()) {
        my $v_weight = $g->get_attr($vertex, 'magnitude');
        $g_weight += $v_weight;
    }
    my $w = _weight_of($data);
    is $g_weight, $w, "magnitude: $g_weight = $w";
    $n++;
}

# Populate with both weight and magnitude.
{
    my $g = eval { Graph::Weighted->new() };
    isa_ok $g, GW, 'weight and magnitude';
    eval { $g->populate($weight_dataset->[-1]) };
    print $@ if $@;
    ok !$@, 'populate weight data';
    my $g_weight = 0;
    for my $vertex ($g->vertices()) {
        my $v_weight = $g->get_weight($vertex);
        $g_weight += $v_weight;
    }
    my $w = _weight_of($weight_dataset->[-1]);
    is $g_weight, $w, "weight: $g_weight = $w";

    eval { $g->populate($magnitude_dataset->[-1], '', 'magnitude') };
    print $@ if $@;
    ok !$@, 'populate magnitude data';
    $g_weight = 0;
    for my $vertex ($g->vertices()) {
        my $v_weight = $g->get_attr($vertex, 'magnitude');
        $g_weight += $v_weight;
    }
    $w = _weight_of($magnitude_dataset->[-1]);
    is $g_weight, $w, "magnitude: $g_weight = $w";
}

sub _weight_of {
    my $data = shift;
    my $weight = 0;
    for my $i (@$data) {
        $weight += $_ for @$i;
    }
    return $weight;
}
