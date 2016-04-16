//
//  settingsView.swift
//  PCE相机
//
//  Created by Kevin_Feng on 16/4/16.
//  Copyright © 2016年 王浩强. All rights reserved.
//

import UIKit

class settingsView: UIViewController,UITableViewDataSource,UITableViewDelegate {

    let tag:Int = 1
    
    var settingDataDictionary:NSDictionary! = nil
    @IBOutlet var settingTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        settingTableView.dataSource = self
        // Do any additional setup after loading the view.
        settingDataDictionary = NSDictionary(contentsOfURL: NSBundle.mainBundle().URLForResource("settingData", withExtension: "plist")!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (settingDataDictionary?.count)!
    }
    func tableView(tableView:UITableView, numberOfRowsInSection section:Int) -> Int
    {
        return (settingDataDictionary?.allValues[section] as! NSArray).count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
//        let cell:UITableViewCell=UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "cell")
        let cell = tableView.dequeueReusableCellWithIdentifier("settingTableViewCell", forIndexPath: indexPath) as UITableViewCell
        let label = cell.viewWithTag(tag) as! UILabel
        label.text = (settingDataDictionary?.allValues[indexPath.section] as! NSArray).objectAtIndex(indexPath.row) as! String
        print("1\(label.text)")
//        cell.textLabel.text="row#\(indexPath.row)"
//        cell.detailTextLabel.text="subtitle#\(indexPath.row)"
        
        return cell
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settingDataDictionary?.allKeys[section] as! String
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
