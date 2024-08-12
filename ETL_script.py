from sqlalchemy import create_engine
import pandas as pd

def extract_transform_load(source_db_url, target_db_url):
    """
    Extract data from the source database, transform it using pandas, and load it into the target database.

    Parameters:
    - source_db_url: str, the connection URL for the source database.
    - target_db_url: str, the connection URL for the target database.
    """
    
    # Create engines for both databases
    source_engine = create_engine(source_db_url)
    target_engine = create_engine(target_db_url)

    try:
        # Extract user IDs from the users table
        users_df = pd.read_sql('SELECT userid FROM users', source_engine)

        for user_id in users_df['userid']:
            # Prepare the query with the current user ID
            query = f"""
            SELECT 
                e1.location AS location,
                e1.starttime AS StartTime1,
                e1.endtime AS EndTime1,
                e2.starttime as StartTime2,
                e2.endtime as EndTime2,
                ui2.username AS user_swiped,
                ui.interaction as interaction
            FROM 
                master e1
            JOIN 
                master e2
                ON e1.location = e2.location
                AND e1.starttime < e2.endtime
                AND e1.endtime > e2.starttime
            JOIN 
                user_info ui2 
                ON e2.userid = ui2.userid
            LEFT JOIN 
                user_interaction ui
                ON (ui.userid1 = e1.userid AND ui.userid2 = e2.userid)
                OR (ui.userid1 = e2.userid AND ui.userid2 = e1.userid)
            WHERE 
                e1.userid = {user_id}
                AND e2.userid <> {user_id}
                AND ui.interaction IS NOT NULL
            ORDER BY 
                e1.location, e1.starttime;
            """
            
            # Fetch the data for the current user
            user_data_df = pd.read_sql(query, source_engine)
            
            user_data_df['starttime1'] = pd.to_datetime(user_data_df['starttime1'], format='%H:%M:%S').dt.time
            user_data_df['endtime1'] = pd.to_datetime(user_data_df['endtime1'], format='%H:%M:%S').dt.time
            user_data_df['starttime2'] = pd.to_datetime(user_data_df['starttime2'], format='%H:%M:%S').dt.time
            user_data_df['endtime2'] = pd.to_datetime(user_data_df['endtime2'], format='%H:%M:%S').dt.time

    # Calculate the maximum of the start times
            user_data_df['intersection_start_time'] = user_data_df[['starttime1', 'starttime2']].max(axis=1)

    # Calculate the minimum of the end times
            user_data_df['intersection_end_time'] = user_data_df[['endtime1', 'endtime2']].min(axis=1)

            user_data_df = user_data_df.drop(columns=['starttime1', 'starttime2', 'endtime1', 'endtime2'])

            user_data_df['interaction'] = pd.Categorical(user_data_df['interaction'], categories=['Connect', 'Ignore', 'Already know'])
            # Load the transformed data into the corresponding user_userid table
            user_table_name = f"user_{user_id}"
            user_data_df.to_sql(user_table_name, target_engine, if_exists='append', index=False)

    finally:
        # Close the database connections
        source_engine.dispose()
        target_engine.dispose()
    
    
