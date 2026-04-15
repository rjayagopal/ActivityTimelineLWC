/*
 *  Copyright (c) 2018, salesforce.com, inc.
 *  All rights reserved.
 *  SPDX-License-Identifier: BSD-3-Clause
 *  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 *  @description    Apex data provider for Tasks that Salesforce has archived (IsArchived = true).
 *                   Uses ALL ROWS like SampleApexDataProvider so archived rows are returned.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class ArchivedTasksDataProvider extends timeline.AbstractTimelineDataProvider {

    /**
     * When true in a test context, getData omits the IsArchived filter so unit tests can exercise
     * the query and map logic with inserted Tasks (IsArchived is not settable in tests).
     */
    @TestVisible
    private static Boolean bypassArchivedFilterForTests = false;

    /**
     * @description The child object name
     * @return  String
     */
    global override String getObjectName() {
        return 'Task';
    }

    /**
     * @description The label of the relationship name of the child object
     * @return  String
     */
    global override String getRelationshipName() {
        return 'ArchivedTasks';
    }

    /**
     * @description The field that is used as the title (flow step: Title field)
     * @return  String
     */
    global override String getTitleField() {
        return 'Subject';
    }

    /**
     * @description The field that is used as reference date (flow step: Date field)
     * @return  String
     */
    global override String getDateField() {
        return 'LastModifiedDate';
    }

    /**
     * @description The fields that are shown when expanded (flow step: Display fields)
     * @return  List<String>
     */
    global override List<String> getFieldsToDisplay() {
        return new List<String>{
            'Description'
        };
    }

    /**
     * @description Defines the label and the type of the fields to display
     *              Only needed when it's no salesforce object
     * @return  List<TimelineFieldType>
     */
    global override List<timeline.TimelineFieldType> getFieldsToDisplayWithTypes() {
        return new List<timeline.TimelineFieldType>();
    }

    /**
     * @description To put in another base url than the current salesforce instance
     * @return  String
     */
    global override String getBaseUrlForRecordDetail() {
        return '';
    }

    /**
     * @description The field that represents the record Id
     * @return  String
     */
    global override String getRecordIdentifierField() {
        return 'Id';
    }

    /**
     * @description Returns archived Tasks related to the parent record (e.g. Account via WhatId).
     * @param   recordId    The id of the parent record
     * @param   dateFilter  The dateFilter coming from the filters in the panel
     * @return  List<Object>
     */
    @SuppressWarnings('PMD.ApexSOQLInjection')
    global override List<Object> getData(Id recordId, String dateFilter) {
        List<Object> result = new List<Object>();
        if (!Schema.sObjectType.Task.isAccessible()
            || !Schema.sObjectType.Task.fields.IsArchived.isAccessible()) {
            return result;
        }

        String dateFilterStr;
        if (!String.isBlank(dateFilter) && !dateFilter.contains('All Time')) {
            dateFilterStr = dateFilter;
        }

        String query = 'SELECT Id, Subject, Description, CreatedDate, LastModifiedDate, TaskSubtype, ActivityDate, IsClosed, IsArchived, OwnerId, Owner.Name, WhoId, Who.Name';
        query += ' FROM Task';
        query += ' WHERE WhatId = \'' + String.escapeSingleQuotes(String.valueOf(recordId)) + '\'';
        if (!(Test.isRunningTest() && bypassArchivedFilterForTests)) {
            query += ' AND IsArchived = true';
        }

        if (!String.isBlank(dateFilterStr)) {
            String dateCondition = '';
            for (String individualFilter : dateFilterStr.split(',')) {
                if (!String.isBlank(dateCondition)) {
                    dateCondition += ' OR ';
                }
                dateCondition += this.getDateField() + '=' + individualFilter;
            }
            query += ' AND (' + dateCondition + ')';
        }

        query += ' AND IsDeleted = false';
        query += ' WITH USER_MODE';
        query += ' ORDER BY ' + this.getDateField() + ' DESC ALL ROWS';

        for (Task item : Database.query(query)) {
            Map<String, Object> obj = new Map<String, Object>();
            obj.put('Id', item.Id);
            obj.put('Subject', item.Subject);
            obj.put('CreatedDate', item.CreatedDate);
            obj.put('ActivityDate', item.ActivityDate);
            obj.put('IsClosed', item.IsClosed);
            obj.put('IsArchived', item.IsArchived);
            obj.put('Description', item.Description);
            obj.put('TaskSubtype', item.TaskSubtype);
            obj.put('LastModifiedDate', item.LastModifiedDate);
            Map<String, String> ownerNameMap = new Map<String, String>();
            ownerNameMap.put('Name', item.Owner.Name);
            obj.put('OwnerId', item.OwnerId);
            obj.put('Owner', ownerNameMap);
            Map<String, String> whoNameMap = new Map<String, String>();
            whoNameMap.put('Name', item.Who.Name);
            obj.put('WhoId', item.WhoId);
            obj.put('Who', whoNameMap);
            result.add(obj);
        }
        return result;
    }

    /**
     * @description Returns if the child object is a salesforce object
     * @return  Boolean
     */
    global override Boolean isSalesforceObject() {
        return true;
    }

    /**
     * @description Returns if UI api is not supported (like with Task)
     * @return  Boolean
     */
    global override Boolean isUiApiNotSupported() {
        return true;
    }
}