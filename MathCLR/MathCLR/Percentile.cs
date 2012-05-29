using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.IO;
using Microsoft.SqlServer.Server;

/* 
 Attribution: Written by Dev Nambi, with feedback from Frank Gese
 */

[Serializable]
[Microsoft.SqlServer.Server.SqlUserDefinedAggregate(Format.UserDefined, IsInvariantToDuplicates = false, IsInvariantToNulls = true, IsNullIfEmpty = true, IsInvariantToOrder = true, MaxByteSize = -1)]
public struct Percentile : Microsoft.SqlServer.Server.IBinarySerialize
{
    public void Init()
    {
        // Put your code here
        doubleList = new List<double>();
    }

    public void Accumulate(SqlDouble value, SqlInt16 percentile)
    {
        // Put your code here
        if (value.IsNull != true)
        {
            doubleList.Add(value.Value);
        }

        if (percentile.IsNull != true)
        {
            if (percentile.Value > 100)
            {
                this.percentile = 100;
            }
            else
            {
                this.percentile = percentile.Value;
            }
        }
    }

    public void Merge(Percentile Group)
    {
        // Put your code here
        List<double> secondDoubleList = Group.DoubleList;
        foreach (double d in secondDoubleList)
        {
            doubleList.Add(d);
        }

        this.percentile = Group.PercentileValue;
    }

    public SqlDouble Terminate()
    {
        // Put your code here
        doubleList.Sort();
        double percentileResult;
        double indexToParse;
        int indexToRetrieve;

        if (doubleList.Count == 0)
        {
            return new SqlDouble();
        }

        indexToParse = this.percentile / 100.0 * doubleList.Count + 0.50;

        if (indexToParse < 0)
        {
            indexToParse = 0;
        }
        
        indexToRetrieve = Convert.ToInt32(indexToParse);
        if (indexToRetrieve >= doubleList.Count)
        {
            indexToRetrieve = doubleList.Count - 1;
        }

        percentileResult = doubleList[indexToRetrieve];


        return new SqlDouble(percentileResult);
    }


    /*
     * The binary layout is as follows:
     * The first 2 bytes are the percentile
     * * Each 8 bytes is a double
     */
    public void Read(BinaryReader binaryReader)
    {
        if (doubleList == null)
        {
            doubleList = new List<double>();
        }

        this.percentile = binaryReader.ReadInt16();

        long readerLength = binaryReader.BaseStream.Length;
        while (binaryReader.BaseStream.Position <= (readerLength - 8))
        {
            doubleList.Add(binaryReader.ReadDouble());
        }
    }

    public void Write(BinaryWriter binaryWriter)
    {
        binaryWriter.Write(PercentileValue);
        foreach (double d in doubleList)
        {
            binaryWriter.Write(d);
        }
    }

    // This is a place-holder member field
    private List<double> doubleList;
    private short percentile;

    public List<double> DoubleList
    {
        get
        {
            return this.doubleList;
        }
    }

    public short PercentileValue
    {
        get
        {
            return this.percentile;
        }
    }

}
