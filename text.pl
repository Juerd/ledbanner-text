#!/usr/bin/perl -w
use strict;
use Time::HiRes qw(sleep);

undef $/;
$| = 1;

sub read_image {
    my ($color, $text) = @_;

    open my $pipe, '-|', 'convert',
        '-gravity' => 'center',
        '-size' => 'x8',
        '-font' => 'nokiafc22.ttf',
        '-background' => 'black',
        '-pointsize' => 8,
        '-fill' => $color,
        '-depth' => 8,
        '-kerning' => 0,
        '-interword-spacing' => 5,
#        '-resize' => 'x8!',
        "label:\Q$text",
        'RGB:-'
        or warn $!;
    return readline $pipe;
}

my $color = shift @ARGV;
my $text = shift @ARGV;
my $image = read_image($color, $text);
my $width = length($image) / (8 * 3);
my $next_image;

for my $index (0..0) {
    for my $x (($index == 0 ? 1 : 80) .. 80 + $width) {
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
#        sleep length($text) < 40 ? .015 : .010;
        sleep 0.0253;
    }
    # $image = $next_image;

}

close STDOUT;
