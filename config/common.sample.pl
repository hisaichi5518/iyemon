{
    'MongoDB::Connection' => {
        host       => 'localhost',
        port       => 27017,
        database   => 'test',
        collection => 'test',
    },
    boostrap => {
        web => ['-p' => 50004],
    },
}
