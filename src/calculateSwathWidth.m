function swathWidth = calculateSwathWidth(altitude, FOV)

    swathWidth = 2 * altitude * tand(FOV / 2);

end