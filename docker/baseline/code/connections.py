import findspark
findspark.init()  # Initialize Spark
from pyspark.sql import SparkSession
import psycopg2
import socket
import logging

logging.basicConfig( level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

##############################################
# Creating connection to PostgreSQL database #
##############################################

def postgres_connection(pg_host_nm: str,pg_port_nmbr: int, pg_db_nm: str, pg_usr_nm: str, pg_pswd: str) -> psycopg2.extensions.cursor :
    """
    Establish a connection to a PostgreSQL database.

    Args:
        host (str): Hostname or IP address of the PostgreSQL server.
        port (int): Port number on which PostgreSQL is listening.
        database (str): Name of the database to connect to.
        user (str): Username used to authenticate.
        password (str): Password used to authenticate.

    Returns:
        psycopg2.extensions.connection: A live database connection object.

    Raises:
        psycopg2.DatabaseError: If there is any issue connecting to PostgreSQL.
    """
    
    try:
        # Log the attempt
        logging.info(f"Attempting to connect to PostgreSQL at {pg_host_nm}:{pg_port_nmbr}, database: {pg_db_nm}")
        
        # Create a connection to PostgreSQL
        connection = psycopg2.connect(host=pg_host_nm, # Replace with your PostgreSQL container/service name
            port=pg_port_nmbr, # Default PostgreSQL port
            database=pg_db_nm, # Replace with your database name
            user=pg_usr_nm, # Replace with your username
            password=pg_pswd # Replace with your password
        )
        # Automatically commits the changes
        connection.autocommit = True
        # Log successful connection
        logging.info("Connection to PostgreSQL established successfully.")

        # Return the live connection object
        return connection.cursor()
    
    except psycopg2.DatabaseError as e:
        # Log the error with full stack trace
        logging.error("Failed to connect to PostgreSQL.", exc_info=True)
        raise e

###############################################################################################
# Creating SparkSession and connecting to spark container, if the container is up and running #
###############################################################################################

def sprk_contr_status(sprk_host: str, sprk_port: int) -> bool:
    """
    Check if the Spark Master container is up and accepting connections.

    Args:
        host (str): Host address of the Spark master.
        port (int): Port number of the Spark master.

    Returns:
        bool: True if Spark container is reachable, False otherwise.
    """
    try:
        with socket.create_connection((sprk_host, sprk_port), timeout=5):
            logging.info(f"Successfully connected to Spark container at {sprk_host}:{sprk_port}")
            return True
    except (socket.timeout, ConnectionRefusedError, OSError) as e:
        logging.warning(f"Unable to reach Spark container at {sprk_host}:{sprk_port}: {e}")
        return False

def create_spark_session(sprk_mstr_host: str = "spark-master",sprk_mstr_port: int = 7077, app_name: str = 'DCONAP',master_typ: str = "local[*]", sprk_exutr_mem: str = '1g',sprk_drvr_mem: str = '1g') -> SparkSession:
    """
    Create a SparkSession. Connect to Spark container if available, else create local SparkSession.

    Args:
        app_name (str): Name of the Spark application.

    Returns:
        SparkSession: A configured SparkSession object.
    """
    try:
        if sprk_contr_status(sprk_mstr_host, sprk_mstr_port):
            # Connect to Spark container cluster
            logging.info("Creating SparkSession connected to Spark container cluster.")
            master_typ = f"spark://{sprk_mstr_host}:{sprk_mstr_port}"
            spark = SparkSession.builder \
                .appName(app_name) \
                .master(master_typ) \
                .config("spark.executor.memory", sprk_exutr_mem) \
                .config("spark.driver.memory", sprk_drvr_mem) \
                .getOrCreate()
        else:
            # Fall back to local mode
            logging.info("Creating local SparkSession inside Jupyter Notebook container.")
            spark = SparkSession.builder \
                .appName(app_name) \
                .master(master_typ) \
                .config("spark.executor.memory", sprk_exutr_mem) \
                .config("spark.driver.memory", sprk_drvr_mem) \
                .getOrCreate()

        logging.info("SparkSession created successfully.")
        return spark

    except Exception as e:
        logging.error("Failed to create SparkSession.", exc_info=True)
        raise e