package Search::Sitemap::URL::Video;
use Moose;
use Search::Sitemap::Types;
use MooseX::Types::URI qw( Uri );
use MooseX::Types::Moose qw( Str HashRef Bool ArrayRef CodeRef );
use HTML::Entities qw( encode_entities );

extends 'Search::Sitemap::URL';

has 'player_loc'            => (
    is          => 'rw',
    isa         => Uri,
    coerce      => 1,
    predicate   => 'has_player_loc',
    clearer     => 'clear_player_loc',
);

has 'content_loc'           => (
    is          => 'rw',
    isa         => Uri,
    coerce      => 1,
    predicate   => 'has_content_loc',
    clearer     => 'clear_content_loc',
);

has 'thumbnail_loc'         => (
    is          => 'rw',
    isa         => Uri,
    coerce      => 1,
    predicate   => 'has_thumbnail_loc',
    clearer     => 'clear_thumbnail_loc',
);

has 'title'                 => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_title',
);

has 'description'           => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_description',
);

has 'expiration_date'       => (
    is          => 'rw',
    isa         => 'DateTime',
    predicate   => 'has_expiration_date',
);

has 'duration'              => (
    is          => 'rw',
    isa         => 'Int',
    predicate   => 'has_duration',
);

has 'rating'                => (
    is          => 'rw',
    isa         => 'Num',
    predicate   => 'has_rating',
);

has 'view_count'            => (
    is          => 'rw',
    isa         => 'Int',
    predicate   => 'has_view_count',
);

has 'publication_date'      => (
    is          => 'rw',
    isa         => 'DateTime',
    predicate   => 'has_publication_date',
);

# TODO permitir array, generar multiples elementos
has 'tag'                   => (
    is          => 'rw',
    isa         => ArrayRef[Str],
    predicate   => 'has_tag',
);

# TODO permitir array, generar multiples elementos
has 'category'              => (
    is          => 'rw',
    isa         => ArrayRef[Str],
    predicate   => 'has_category',
);

has 'family_friendly'       => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 1,
    predicate   => 'has_family_friendly',
);

has 'fields'                => (
    is          => 'rw',
    isa         => ArrayRef[Str],
    default     => sub{  [ qw/
                            player_loc
                            content_loc
                            thumbnail_loc
                            title
                            description
                            expiration_date
                            duration
                            rating
                            view_count
                            publication_date
                            tag
                            category
                            family_friendly
                        /] },
);

sub _content_loc_as_elt {
    my $self = shift;
    return unless $self->has_content_loc;
    my $loc = XML::Twig::Elt->new(
        '#PCDATA' => encode_entities( $self->content_loc->as_string )
    );
    $loc->set_asis( 1 );
    return $loc;
}

sub _expiration_date_as_elt {
    my $self = shift;
    return unless $self->has_expiration_date;
    my $elt = XML::Twig::Elt->new(
        '#PCDATA'   => $self->expiration_date->strftime('%FT%T%z')
    );
    $elt->set_asis(1);
    return $elt;

}

sub _publication_date_as_elt {
    my $self = shift;
    return unless $self->has_publication_date;
    my $elt = XML::Twig::Elt->new(
        '#PCDATA'   => $self->publication_date->strftime('%FT%T%z')
    );
    $elt->set_asis(1);
    return $elt;
}

sub _player_loc_as_elt {
    my $self = shift;
    return unless $self->has_player_loc;
    my $loc = XML::Twig::Elt->new(
        '#PCDATA' => encode_entities( $self->player_loc->as_string )
    );
    $loc->set_asis( 1 );
    return $loc;
}

sub has_video {
    my $self = shift;
    return $self->has_content_loc || $self->has_player_loc;
}

sub build_video_elts {
    my $self = shift;

    my @elements;
    for my $f (@{ $self->fields }) {
        warn "Doing [$f]";
        my $exists = $self->can( "has_$f" );
        next if $exists and not $self->$exists;

        my $method = '_'.$f.'_as_elt';
        my $val;
        if ( $self->can( $method ) ) {
            $val = $self->$method();
        } else {
            $val = XML::Twig::Elt->new( '#PCDATA' => $self->$f() );
        }
        next unless $val;
        next unless blessed $val;
        next unless $val->isa( 'XML::Twig::Elt' );
        push( @elements, $val->wrap_in( "video:$f" ) );
    }

    return @elements;
}

override 'as_elt'   => sub {
    my $self = shift;

    my $elt = super();

    if( $self->has_video ) {
        $elt->insert_new_elt( 'video:video', {}, $self->build_video_elts );
    }

    return $elt;
};


__PACKAGE__->meta->make_immutable;
1;
