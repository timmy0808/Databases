from migration.cdc_worker import cycle
from validation.run_validation import main as validate

def main():
    print('CUTOVER: stop source application writes before continuing.')
    while True:
        n=cycle()
        if n==0: break
        print(f'Drained {n} changes.')
    validate()
    print('CUTOVER COMPLETE: switch application secret/connection string to PostgreSQL.')

if __name__=='__main__': main()
