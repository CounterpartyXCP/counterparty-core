for f in counterpartylib/test/fixtures/scenarios/*.new.*; do
    mv $f ${f/.new/''}
done