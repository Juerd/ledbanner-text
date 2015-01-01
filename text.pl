#!/usr/bin/perl -w
use strict;
use Time::HiRes qw(sleep);
use Image::Magick;
use File::Slurp;
use List::Util qw(sum);

undef $/;
$| = 1;

my $hex_re = '[0-9A-Fa-f]';
my $color_re = "(?:#$hex_re\{3}|#$hex_re\{6})";
my $font_re = '(?:\{[a-z0-9]+\.ttf\})';

my @font_opts = (
    gravity => 'West',
    pointsize => 8,
    kerning => 0,
    'interword-spacing' => 3,
);

sub read_image {
    my ($color, $text) = @_;
    my $font = 'nokiafc22.ttf';

    my $image = Image::Magick->new;
    $image->Set(size => '5000x8', depth => 8);
    $image->ReadImage('canvas:black');

    my @input = split(/($color_re|$font_re)/, $text);
    my @output;
    my @width;
    my $i = 0;
    PIECE: foreach my $piece (grep defined && length, @input) {
        if ($piece =~ /^($color_re)$/) {
            $color = $1;
            next PIECE;
        }
        if ($piece =~ /^($font_re)$/) {
            my $fn = $1;
            $fn =~ s/^\{//;
            $fn =~ s/\}$//;
            if (-e $fn and -r $fn) {
		$font = $fn;
	        next PIECE;
            }
        }
        # see http://www.imagemagick.org/script/perl-magick.php#misc
        my $width = ($image->QueryFontMetrics(
            @font_opts,
            font => $font,
            text => $piece
        ))[4];

        push @output, {
            width => $width,
            color => $color,
            font  => $font,
            text  => $piece,
        };
    }

    # create new empty image with width
    $image = Image::Magick->new;
    $image->Set(size => sum(map $_->{width}, @output) . 'x8', depth => 8);
    $image->ReadImage('canvas:black');

    my $x = 0;
    $i = 0;

    foreach my $piece (@output) {
        $image->Annotate(
            @font_opts,
            x => $x,
            font => $piece->{font},
            fill => $piece->{color},
            text => $piece->{text}
        );
        $x += $piece->{width};
    }

    return $image->ImageToBlob(magick => "RGB");
}

my $color = shift @ARGV;
my $text = shift @ARGV;
my $image = read_image($color, $text);
my $width = length($image) / (8 * 3);
my $next_image;

for my $x (1 .. 80 + $width) {
    my $out = "\0" x 1920;
    for my $y (0..7) {
        my $src_left = $y * $width;
        if ($x > 80) {
            $src_left += $x - 80;
        }
        my $dst_left = $y * 80;
        my $target   = $dst_left + (80 - ($x > 80 ? 80 : $x));
        my $length   = ($x > 80 ? 80 : $x);
        if ($x > $width) {
            $length += $width - $x;
        }

        substr $out, $target * 3, $length * 3, #"\x40" x $length;
            substr $image, $src_left * 3, $length * 3;
    }
    print $out;
    sleep 0.0253;
}

close STDOUT;
