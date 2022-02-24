import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { CommentedLinesAppRoutingModule } from './commentedlines-application-routing.module';
import { CommentedLinesAppComponent } from './commentedlines-application.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';


@NgModule({
    imports: [CommonModule, CommentedLinesAppRoutingModule, PageHeaderModule,DataTablesModule, NgbModule],
    declarations: [CommentedLinesAppComponent]
})
export class CommentedLinesAppModule {}
