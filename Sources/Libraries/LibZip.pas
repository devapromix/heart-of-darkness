unit LibZip;

interface

function Save(const ArchiveFileName, AFileName, AText: AnsiString): Boolean; external 'LibZip.dll';
function Load(const ArchiveFileName, AFileName: AnsiString): AnsiString; external 'LibZip.dll';
function FileExists(const ArchiveFileName, AFileName: AnsiString): Boolean; external 'LibZip.dll';

implementation

end.