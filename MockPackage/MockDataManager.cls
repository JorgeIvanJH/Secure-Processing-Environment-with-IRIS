Class MockPackage.MockDataManager Extends %Persistent
{

ClassMethod AdjustDataSize(csvpath As %String, numrows As %Integer) [ Language = python ]
{
    """
    Takes CSV from csvpath and adjusts its size to have exactly numrows rows.
    New CSV is saved in the same directory with suffix _nr{numrows} before file extension.
    Meant ONLY for testing purposes.
    e.g:
        do ##class(MockPackage.MockDataManager).AdjustDataSize("/dur/data/healthcare_noshows_appointments.csv",10000)
    """
    import os
    import pandas as pd
    
    path, filename = os.path.split(csvpath)
    filename, ext = os.path.splitext(filename)
    df = pd.read_csv(csvpath)
    n_rows = df.shape[0]
    nrepeats, remainder = numrows // n_rows, numrows % n_rows
    df = pd.concat([df]*nrepeats + [df.sample(remainder)], ignore_index=True)
    new_datapath = os.path.join(path, f"{filename}_nr{numrows}{ext}")
    df.to_csv(new_datapath, index=False)
}

Storage Default
{
<Data name="MockDataDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^MockPackage.MockDataD</DataLocation>
<DefaultData>MockDataDefaultData</DefaultData>
<IdLocation>^MockPackage.MockDataD</IdLocation>
<IndexLocation>^MockPackage.MockDataI</IndexLocation>
<StreamLocation>^MockPackage.MockDataS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
