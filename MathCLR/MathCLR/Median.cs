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
[Microsoft.SqlServer.Server.SqlUserDefinedAggregate(Format.UserDefined, IsInvariantToDuplicates=false, IsInvariantToNulls=false, IsNullIfEmpty=true, IsInvariantToOrder=true, MaxByteSize=-1)]
public struct Median : Microsoft.SqlServer.Server.IBinarySerialize
{
    public void Init()
    {
        doubleList = new List<double>();
    }

    public void Accumulate(SqlDouble input)
    {
        if (input.IsNull != true)
        {
            doubleList.Add(input.Value);
        }
    }

    public void Merge(Median Group)
    {
        List<double> secondDoubleList = Group.DoubleList;
        foreach (double d in secondDoubleList) 
        {
            doubleList.Add(d);
        }
    }

    public SqlDouble Terminate()
    {
        doubleList.Sort();
        double medianValue;
        if (doubleList.Count == 0)
        {
            return new SqlDouble();
        }
        if (doubleList.Count % 2 != 0)
        {
            medianValue = doubleList[doubleList.Count / 2];
        }
        else
        {
            // if there are an equal number of values, the median is the mean of the 2 middle values
            medianValue =
                (doubleList[doubleList.Count / 2] + doubleList[(doubleList.Count - 1) / 2])
                / 2.0;
                //Double.Parse(doubleList[(doubleList.Count + 1) / 2].ToString());
        }
        return new SqlDouble(medianValue);
    }


    /*
     * The binary layout is as follows:
     * Each 8 bytes is a double
     */
    public void Read(BinaryReader binaryReader)
    {
        if (doubleList == null)
        {
            doubleList = new List<double>();
        }
        long readerLength = binaryReader.BaseStream.Length;
        while (binaryReader.BaseStream.Position <= (readerLength - 8))
        {
            double toAdd = binaryReader.ReadDouble();
            if (!toAdd.Equals(double.NaN))
            {
                doubleList.Add(toAdd);
            }
            else
            {
                doubleList.TrimExcess();
                break;
            }
            // detect NaN and exit loop to prevent reader adding "0.0" values to the list
            /*if (doubleList[doubleList.Count - 1].Equals(double.NaN))
            {
                doubleList.RemoveAt(doubleList.Count - 1);
                doubleList.TrimExcess();
                break;
            }*/
        }
    }

    public void Write(BinaryWriter binaryWriter)
    {
        foreach (double d in doubleList)
        {
            binaryWriter.Write(d);
        }
        // Here's where the magic happens:
        // adding an NaN as "exit flag" for Read() method 
        binaryWriter.Write(double.NaN);
    }

    // This is a place-holder member field
    private List<double> doubleList;

    public List<double> DoubleList
    {
        get
        {
            return this.doubleList;
        }
    }

}
