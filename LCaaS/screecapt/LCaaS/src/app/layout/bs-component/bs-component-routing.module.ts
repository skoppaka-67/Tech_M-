import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { BsComponentComponent } from './bs-component.component';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

const routes: Routes = [
    {
        path: '',
        component: BsComponentComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class BsComponentRoutingModule {}
