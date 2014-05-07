package Iyemon::Web;

use strict;
use warnings;
use utf8;
use Kossy;
use Scalar::Util qw/looks_like_number blessed/;
use DateTime;
use DateTime::Format::Strptime;
use MongoDB;
use Iyemon::Config;

get '/' => sub {
    my ($self, $c) = @_;
    $c->render('index.tx', {config => Iyemon::Config->current});
};

get '/search' => sub {
    my ($self, $c) = @_;

    my $mongo_config = config->param('MongoDB::Connection');
    my $mongo = MongoDB::Connection->new($mongo_config)
        ->get_database($mongo_config->{database})
        ->get_collection($mongo_config->{collection});

    my $opts = {limit => 100};
    my $criteria = {};
    my @num_keys = @{config->param('num_keys') || [qw/uid/]};
    my @str_keys = @{config->param('str_keys') || [qw/type/]};

    for my $key (@num_keys) {
        $criteria->{$key} = $c->req->param($key) + 0
            if $c->req->param($key);
    }
    for my $key (@str_keys) {
        $criteria->{$key} = $c->req->param($key)
            if $c->req->param($key);
    }

    my %date;
    my $strp = DateTime::Format::Strptime->new(pattern => '%Y-%m-%dT%H:%M');
    for my $type (qw/start end/) {
        if (my $date = $c->req->param("$type\_date")) {
            my $t = $strp->parse_datetime($date);
            $date{$type} = $t;
        }
        else {
            if ($type eq 'start') {
                $c->halt(400);
            }
            elsif ($type eq 'end') {
                my $dt = DateTime->now;
                $date{$type} = $dt;
            }
        }
    }
    $criteria->{time} = {'$gte' => $date{start}, '$lte' => $date{end}};
    my $page = $c->req->param('page') || 1;
    if ($page ne 'NaN' && looks_like_number $page) {
        $opts->{page} = $page;
    }
    else {
        $c->halt(400);
    }

    %date = map {
        my $dt = $date{$_};
        $dt->set_time_zone('Asia/Tokyo');
        $_ => "$dt";
    } keys %date;

    my $obj = {};
    if ($c->req->param("count")) {
        my %args = map { $c->req->param($_) ? ($_ => $c->req->param($_)) : () } @num_keys, @str_keys, 'date', 'page';
        $obj = {
            %args,
            %date,
            result => $mongo->count($criteria) || 0,
        };
    }
    else {
        my @logs = $mongo->find($criteria, $opts)->all;
        my $results = [];
        if (@logs) {
            $results = [map { _jsonize_log($_) } @logs];
        }

        $obj = {
            results => $results,
            %date,
        };
    }

    $c->render_json($obj);
};

sub _jsonize_log {
    my $obj = shift;

    for my $key (keys %$obj) {
        my $v = $obj->{$key};
        if ( blessed $v && $v->isa("DateTime") ) {
            $v->set_time_zone(config->param('time_zone') || 'Asia/Tokyo');
        }
        $obj->{$key} = sprintf "%s", $v
            if blessed $v;
    }
    $obj;
}

1;
