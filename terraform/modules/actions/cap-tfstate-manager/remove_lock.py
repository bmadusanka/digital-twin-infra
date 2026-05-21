import json, sys, time, argparse
from datetime import datetime
import boto3

def get_lock(dynamodb, table, lock_id):
    try:
        return dynamodb.get_item(
            TableName=table,
            Key={'LockID': {'S': lock_id}}
        ).get('Item')
    except Exception as e:
        sys.exit(f"Error fetching lock: {e}")

def delete_lock(dynamodb, table, lock_id):
    try:
        dynamodb.delete_item(
            TableName=table,
            Key={'LockID': {'S': lock_id}}
        )
        print(f"Removed lock '{lock_id}'.")
    except Exception as e:
        sys.exit(f"Error deleting lock: {e}")

def parse_created(item):
    try:
        raw = item.get('Info', {}).get('S')
        if not raw:
            return None
        created = json.loads(raw).get('Created', '').strip()
        if not created:
            return None
        try:
            return int(datetime.strptime(created, "%Y-%m-%dT%H:%M:%SZ").timestamp())
        except ValueError:
            dt = datetime.strptime(created, "%y-%m-%dT%H:%M:%S.%f")
            if dt.year < 100:
                dt = dt.replace(year=dt.year + 2000)
            return int(dt.timestamp())
    except Exception:
        return None

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--lock-id', required=True)
    p.add_argument('--table', default='terraform-state-locks')
    p.add_argument('--region', required=True)
    p.add_argument('--force', action='store_true')
    a = p.parse_args()

    db = boto3.client('dynamodb', region_name=a.region)
    item = get_lock(db, a.table, a.lock_id)

    if not item:
        print("No lock found.")
        return

    created = parse_created(item)
    if created is None:
        print("Invalid or missing timestamp. Removing...")
        delete_lock(db, a.table, a.lock_id)
        return

    age = int(time.time()) - created
    print(f"Lock age: {age} seconds.")

    if a.force:
        print("Force flag enabled. Removing lock...")
        delete_lock(db, a.table, a.lock_id)
    elif age >= 3600:
        print("Lock is older than 1 hour. Removing...")
        delete_lock(db, a.table, a.lock_id)
    else:
        print("Lock is too recent. Skipping.")

if __name__ == '__main__':
    main()
