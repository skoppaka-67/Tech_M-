import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { BsComponentEventComponent } from './programprocessflow-eventlist.component';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

const routes: Routes = [
    {
        path: '',
        component: BsComponentEventComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class BsComponentEventRoutingModule {}
