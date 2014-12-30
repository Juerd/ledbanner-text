#!/usr/bin/perl -w
use strict;
use Time::HiRes qw(sleep);
use Image::Magick;
use File::Slurp;

undef $/;
$| = 1;

sub read_image {
    my ($color, $text) = @_;

    # create new image structure
    my $image = Image::Magick->new;
    #$image->Set(debug => 'All');
    $image->Set(size => '5000x8', depth => 8);

    my @pieces = split(/&:&/, $text);
    my @width;
    my @colors;
    my @fonts;
    my $allwidth = 0;
    my $i = 0;
    foreach my $piece (@pieces) {
       $colors[$i] = $color;
       $fonts[$i]  = 'nokiafc22.ttf';
       if ($piece =~ s/^(#[0-9A-Fa-f]{6})//) {
         $colors[$i] = $1;
       }
       if ($piece =~ s/^\{([a-z0-9]+\.ttf)\}//) {
         if (-e $1) {
           $fonts[$i] = $1;
         }
       }
       $piece =~ s/\\//g;
       # print STDERR "DBG: color piece ".$i." = ".$colors[$i].": '".$piece."'\n";
       # create empty image & query width
       $image->ReadImage('canvas:black');
       # see http://www.imagemagick.org/script/perl-magick.php#misc
       my ($x_ppem, $y_ppem, $ascender, $descender, $textwidth, $height, $max_advance, $x1, $y1, $x2, $y2) = $image->QueryFontMetrics(
         gravity => 'West',
         font => $fonts[$i],
         pointsize => 8,
         fill => $color,
         kerning => 0,
         'interword-spacing' => 5,
         text => $piece);
     # printf STDERR "DBG: x_ppem %d, y_ppem %d, ascender %d, descender %d, width %d, height %d, max_advance %d, x1 %d, y1 %d, x2 %d, y3 %d\n", $x_ppem, $y_ppem, $ascender, $descender, $textwidth, $height, $max_advance, $x1, $y1, $x1, $y2;
       $width[$i++] = $textwidth;
       $allwidth += $textwidth;
    }

    # create new empty image with width
    $image = Image::Magick->new;
    $image->Set(size => $allwidth . 'x8', depth => 8);
    $image->ReadImage('canvas:black');

    my $x = 0;
    $i = 0;

    foreach my $piece (@pieces) {
        # printf STDERR "DBG: Announce: %d, text '%s'\n", $x, $piece;
       # write text
       $image->Annotate(
         x => $x,
         gravity => 'West',
         font => $fonts[$i],
         pointsize => 8,
         fill => $colors[$i],
         kerning => 0,
         'interword-spacing' => 5,
         text => $piece);
       $x += $width[$i++];
    }

    # write image
    $image->Write(filename=>'PNG:/tmp/text.pl.png');
    $image->Write(filename=>'RGB:/tmp/text.pl.rgb');

    return read_file('/tmp/text.pl.rgb');
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
