if [ -n "${POSTGRES_USER:-}" ] && [ -n "${POSTGRES_DB:-}" ]; then
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
		GRANT CREATE ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;
	EOSQL
else
	echo "SETUP INFO: No Environment variables given!"
fi
