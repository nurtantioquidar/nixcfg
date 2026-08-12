{ lib
, buildPythonPackage
, python3Packages
, fetchPypi
, isPy3k
,
}:

buildPythonPackage rec {
  version = "2.1.0";
  pyproject = true;
  pname = "beanprice";

  disabled = !isPy3k;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-2Q0mZB97rthEPN/bVUXDj40B+XYE7UrUFzsCNZiYKxM=";
  };

  build-system = with python3Packages; [ setuptools ];

  # Tests require files not included in the PyPI archive.
  doCheck = false;

  propagatedBuildInputs = with python3Packages; [
    beancount
    curl-cffi
    diskcache
    python-dateutil
    requests
  ];

  meta = with lib; {
    homepage = "https://github.com/beancount/beanprice";
    description = "Daily price quotes fetching library for plain-text accounting ";
    longDescription = ''
      A script to fetch market data prices from various sources on the internet and render them for plain text accounting price syntax (and Beancount).

      This used to be located within Beancount itself (at v2) under beancount.prices. This repo will contain all future updates to that script and to those price sources.
    '';
    license = licenses.gpl2Only;
    maintainers = [ ];
  };
}
